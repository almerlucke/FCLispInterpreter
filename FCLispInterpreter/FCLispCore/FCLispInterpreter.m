//
//  FCLispInterpreter.m
//  Lisp
//
//  Created by aFrogleap on 12/19/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "FCLispParser.h"
#import "FCLispParserToken.h"
#import "FCLispInterpreter.h"
#import "FCLispScopeStack.h"
#import "FCLispSymbol.h"
#import "FCLispNumber.h"
#import "FCLispString.h"
#import "FCLispCons.h"
#import "FCLispNIL.h"
#import "FCLispListBuilder.h"
#import "FCLispException.h"
#import "FCLispEvaluator.h"
#import "FCLispArray.h"


#pragma mark - FCLispInterpreterException

/**
 *  Internal interpreter exception types
 */
typedef NS_ENUM(NSInteger, FCLispInterpreterExceptionType)
{
    FCLispInterpreterExceptionTypeEmptyQuote,
    FCLispInterpreterExceptionTypeUnmatchedParenthesis,
    FCLispInterpreterExceptionTypeUnmatchedArrayBrackets,
    FCLispInterpreterExceptionTypeDoubleDottedList,
    FCLispInterpreterExceptionTypeMultipleDottedListCdr,
    FCLispInterpreterExceptionTypeDotOutsideListContext
};


/**
 *  Interpreter exception class
 */
@interface FCLispInterpreterException : FCLispException

@end

@implementation FCLispInterpreterException

+ (NSString *)exceptionName
{
    return @"FCLispInterpreterException";
}

+ (NSString *)reasonForType:(NSInteger)type andUserInfo:(NSDictionary *)userInfo
{
    NSString *reason = @"";
    NSNumber *lineCount = [userInfo objectForKey:@"lineCount"];
    
    switch (type) {
        case FCLispInterpreterExceptionTypeEmptyQuote:
            reason = [NSString stringWithFormat:@"Line %@, empty quote", lineCount];
            break;
        case FCLispInterpreterExceptionTypeUnmatchedParenthesis:
            reason = [NSString stringWithFormat:@"Line %@, unmatched parenthesis", lineCount];
            break;
        case FCLispInterpreterExceptionTypeDoubleDottedList:
            reason = [NSString stringWithFormat:@"Line %@, double dotted list", lineCount];
            break;
        case FCLispInterpreterExceptionTypeMultipleDottedListCdr:
            reason = [NSString stringWithFormat:@"Line %@, multiple cdr's for dotted list", lineCount];
            break;
        case FCLispInterpreterExceptionTypeDotOutsideListContext:
            reason = [NSString stringWithFormat:@"Line %@, dot outside list context", lineCount];
            break;
        case FCLispInterpreterExceptionTypeUnmatchedArrayBrackets:
            reason = [NSString stringWithFormat:@"Line %@, unmatched array brackets", lineCount];
            break;
        default:
            break;
    }
    
    return reason;
}

@end



#pragma mark - FCLispInterpreter

/**
 *  Private interface
 */
@interface FCLispInterpreter ()
{
    FCLispParser *_parser;
    FCLispScopeStack *_scopeStack;
}
@end


@implementation FCLispInterpreter

#pragma mark - Init

- (id)initWithParser:(FCLispParser *)parser andScopeStack:(FCLispScopeStack *)scopeStack
{
    if ((self = [super init])) {
        _parser = parser;
        _scopeStack = scopeStack;
    }
    
    return self;
}

+ (FCLispObject *)interpretFile:(NSString *)filePath withScopeStack:(FCLispScopeStack *)scopeStack
{
    FCLispParser *parser = [[FCLispParser alloc] initWithFileAtPath:filePath];
    FCLispInterpreter *interpreter = [[FCLispInterpreter alloc] initWithParser:parser
                                                                 andScopeStack:scopeStack];
    
    return [interpreter interpret];
}

+ (FCLispObject *)interpretData:(NSData *)data withScopeStack:(FCLispScopeStack *)scopeStack
{
    FCLispParser *parser = [[FCLispParser alloc] initWithData:data];
    FCLispInterpreter *interpreter = [[FCLispInterpreter alloc] initWithParser:parser
                                                                 andScopeStack:scopeStack];
    
    return [interpreter interpret];
}

+ (FCLispObject *)interpretString:(NSString *)string withScopeStack:(FCLispScopeStack *)scopeStack
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    FCLispParser *parser = [[FCLispParser alloc] initWithData:data];
    FCLispInterpreter *interpreter = [[FCLispInterpreter alloc] initWithParser:parser
                                                                 andScopeStack:scopeStack];
    
    return [interpreter interpret];
}


#pragma mark - Inner workings

- (NSDictionary *)lineInfo
{
    return @{@"lineCount": [NSNumber numberWithInteger:_parser.lineCount],
             @"charCount": [NSNumber numberWithInteger:_parser.charCount]};
}

- (FCLispObject *)getLispSymbolWithToken:(FCLispParserToken *)token
{
    FCLispSymbol *sym = [FCLispSymbol genSym:token.value];
    
    // if literal return value immediately
    if (sym.type == FCLispSymbolTypeLiteral) {
        return sym.value;
    }
    
    // return lisp symbol
    return sym;
}

- (FCLispObject *)getLispFloatNumberWithToken:(FCLispParserToken *)token
{
    // create a lisp float number
    return [FCLispNumber numberWithFloatValue:[token.value doubleValue]];
}

- (FCLispObject *)getLispIntegerNumberWithToken:(FCLispParserToken *)token
{
    // create a lisp integer number
    return [FCLispNumber numberWithIntegerValue:[token.value longLongValue]];
}

- (FCLispObject *)getLispStringWithToken:(FCLispParserToken *)token
{
    // create a lisp string
    return [FCLispString stringWithString:token.value];
}

- (FCLispObject *)getLispQuoteList
{
    FCLispListBuilder *listBuilder = [FCLispListBuilder listBuilder];
    
    // add quote symbol as first entry in list
    [listBuilder addCar:[FCLispSymbol genSym:@"quote"]];
    
    // get quoted value
    FCLispObject *value = [self getLispObject];
    
    if (!value) {
        @throw [FCLispInterpreterException exceptionWithType:FCLispInterpreterExceptionTypeEmptyQuote
                                                    userInfo:[self lineInfo]];
    }
    
    [listBuilder addCar:value];
    
    FCLispObject *returnValue = [listBuilder lispList];
    
    return returnValue;
}

- (FCLispObject *)getLispArray
{
    FCLispListBuilder *listBuilder = [FCLispListBuilder listBuilder];
    
    // add quote symbol as first entry in list
    [listBuilder addCar:[FCLispSymbol genSym:@"array"]];
    
    while (YES) {
        FCLispParserToken *token = [_parser getToken];
        
        if (!token) {
            // no closing bracket found to match opening bracket
            @throw [FCLispInterpreterException exceptionWithType:FCLispInterpreterExceptionTypeUnmatchedArrayBrackets
                                                        userInfo:[self lineInfo]];
        } else {
            FCLispObject *value = nil;
            
            if (token.type == FCLispParserTokenTypeEndArray) {
                break;
            } else if (token.type == FCLispParserTokenTypeStartArray) {
                // get new array value
                value = [self getLispArray];
            } else if (token.type == FCLispParserTokenTypeOpenList) {
                // get new list value
                value = [self getLispList];
            } else if (token.type == FCLispParserTokenTypeCloseList) {
                // unmatched parenthesis
                @throw [FCLispInterpreterException exceptionWithType:FCLispInterpreterExceptionTypeUnmatchedParenthesis
                                                            userInfo:[self lineInfo]];
            } else if (token.type == FCLispParserTokenTypeQuote) {
                // get quoted value
                value = [self getLispQuoteList];
            } else if (token.type == FCLispParserTokenTypeSymbol) {
                // get symbol value (symbol or reserved value)
                value = [self getLispSymbolWithToken:token];
            } else if (token.type == FCLispParserTokenTypeFloatNumber) {
                value = [self getLispFloatNumberWithToken:token];
            } else if (token.type == FCLispParserTokenTypeIntegerNumber) {
                value = [self getLispIntegerNumberWithToken:token];
            } else if (token.type == FCLispParserTokenTypeDot) {
                @throw [FCLispInterpreterException exceptionWithType:FCLispInterpreterExceptionTypeDotOutsideListContext
                                                            userInfo:[self lineInfo]];
            } else if (token.type == FCLispParserTokenTypeString) {
                // create a lisp string
                value = [self getLispStringWithToken:token];
            }
            
            [listBuilder addCar:value];
        }
    }
    
    return [listBuilder lispList];
}


- (FCLispObject *)getLispList
{
    FCLispListBuilder *listBuilder = [FCLispListBuilder listBuilder];
    BOOL dotted = NO;
    BOOL dottedValueSet = NO;
    
    while (YES) {
        FCLispParserToken *token = [_parser getToken];
        
        if (!token) {
            // no close parenthesis found to match open parenthesis
            @throw [FCLispInterpreterException exceptionWithType:FCLispInterpreterExceptionTypeUnmatchedParenthesis
                                                        userInfo:[self lineInfo]];
        } else {
            FCLispObject *value = nil;
            
            if (token.type == FCLispParserTokenTypeOpenList) {
                // get new list value
                value = [self getLispList];
            } else if (token.type == FCLispParserTokenTypeCloseList) {
                // close current list
                break;
            } else if (token.type == FCLispParserTokenTypeStartArray) {
                // get new array value
                value = [self getLispArray];
            } else if (token.type == FCLispParserTokenTypeEndArray) {
                @throw [FCLispInterpreterException exceptionWithType:FCLispInterpreterExceptionTypeUnmatchedArrayBrackets
                                                            userInfo:[self lineInfo]];
            } else if (token.type == FCLispParserTokenTypeQuote) {
                // get quoted value
                value = [self getLispQuoteList];
            } else if (token.type == FCLispParserTokenTypeSymbol) {
                // get symbol value (symbol or reserved value)
                value = [self getLispSymbolWithToken:token];
            } else if (token.type == FCLispParserTokenTypeFloatNumber) {
                value = [self getLispFloatNumberWithToken:token];
            } else if (token.type == FCLispParserTokenTypeIntegerNumber) {
                value = [self getLispIntegerNumberWithToken:token];
            } else if (token.type == FCLispParserTokenTypeDot) {
                // dotted list, double check if already dotted
                if (dotted) {
                    @throw [FCLispInterpreterException exceptionWithType:FCLispInterpreterExceptionTypeDoubleDottedList
                                                                userInfo:[self lineInfo]];
                }
                dotted = YES;
            } else if (token.type == FCLispParserTokenTypeString) {
                // create a lisp string
                value = [self getLispStringWithToken:token];
            }
            
            if (dotted) {
                // if dotted, check if cdr is set
                if (dottedValueSet) {
                    @throw [FCLispInterpreterException exceptionWithType:FCLispInterpreterExceptionTypeMultipleDottedListCdr
                                                                userInfo:[self lineInfo]];
                } else if (value) {
                    // set cdr to value and set dottedValueSet to YES, don't allow dotted list cdr reassign
                    dottedValueSet = YES;
                    [listBuilder addCdr:value];
                }
            } else {
                [listBuilder addCar:value];
            }
        }
    }
    
    return [listBuilder lispList];
}

- (FCLispObject *)getLispObject
{
    FCLispObject *value = nil;
    FCLispParserToken *token = [_parser getToken];
    
    if (token) {
        switch (token.type) {
            case FCLispParserTokenTypeStartArray:
                // get a list array
                value = [self getLispArray];
                break;
            case FCLispParserTokenTypeEndArray:
                {
                    @throw [FCLispInterpreterException exceptionWithType:FCLispInterpreterExceptionTypeUnmatchedArrayBrackets
                                                                userInfo:[self lineInfo]];
                }
                break;
            case FCLispParserTokenTypeOpenList:
                // get a list object
                value = [self getLispList];
                break;
            case FCLispParserTokenTypeCloseList:
                // unmatched close list token
                {
                    @throw [FCLispInterpreterException exceptionWithType:FCLispInterpreterExceptionTypeUnmatchedParenthesis
                                                                userInfo:[self lineInfo]];
                }
                break;
            case FCLispParserTokenTypeQuote:
                // get quoted list
                value = [self getLispQuoteList];
                break;
            case FCLispParserTokenTypeSymbol:
                // get symbol (or reserved symbol value)
                value = [self getLispSymbolWithToken:token];
                break;
            case FCLispParserTokenTypeFloatNumber:
                value = [self getLispFloatNumberWithToken:token];
                break;
            case FCLispParserTokenTypeIntegerNumber:
                value = [self getLispIntegerNumberWithToken:token];
                break;
            case FCLispParserTokenTypeDot:
                // dot can only appear in list context
                {
                    @throw [FCLispInterpreterException exceptionWithType:FCLispInterpreterExceptionTypeDotOutsideListContext
                                                                userInfo:[self lineInfo]];
                }
                break;
            case FCLispParserTokenTypeString:
                // lisp string
                value = [self getLispStringWithToken:token];
                break;
            default:
                break;
        }
    }
    
    return value;
}

// interpret parser tokens in given lisp environment
- (FCLispObject *)interpret
{
    FCLispObject *returnValue = [FCLispNIL NIL];
    
    while (YES) {
        FCLispObject *lispObject = [self getLispObject];
        if (lispObject) {
            returnValue = [FCLispEvaluator eval:lispObject withScopeStack:_scopeStack];
        } else {
            break;
        }
    }
    
    return returnValue;
}

@end
