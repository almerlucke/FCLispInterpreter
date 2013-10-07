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


@interface FCLispInterpreter ()
{
    FCLispParser *_parser;
    FCLispScopeStack *_scopeStack;
}
@end

@implementation FCLispInterpreter

#pragma mark - Init/Interpret

- (id)initWithParser:(FCLispParser *)parser andScopeStack:(FCLispScopeStack *)scopeStack
{
    if ((self = [super init])) {
        _parser = parser;
        _scopeStack = scopeStack;
    }
    
    return self;
}

+ (id)interpretFile:(NSString *)filePath withScopeStack:(FCLispScopeStack *)scopeStack
{
    FCLispParser *parser = [[FCLispParser alloc] initWithFileAtPath:filePath];
    FCLispInterpreter *interpreter = [[FCLispInterpreter alloc] initWithParser:parser
                                                                 andScopeStack:scopeStack];
    
    return [interpreter interpret];
}

+ (id)interpretData:(NSData *)data withScopeStack:(FCLispScopeStack *)scopeStack
{
    FCLispParser *parser = [[FCLispParser alloc] initWithData:data];
    FCLispInterpreter *interpreter = [[FCLispInterpreter alloc] initWithParser:parser
                                                                 andScopeStack:scopeStack];
    
    return [interpreter interpret];
}

+ (id)interpretString:(NSString *)string withScopeStack:(FCLispScopeStack *)scopeStack
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    FCLispParser *parser = [[FCLispParser alloc] initWithData:data];
    FCLispInterpreter *interpreter = [[FCLispInterpreter alloc] initWithParser:parser
                                                                 andScopeStack:scopeStack];
    
    return [interpreter interpret];
}

#pragma mark - Inner workings

- (FCLispObject *)getLispSymbolWithToken:(FCLispParserToken *)token
{
    FCLispSymbol *sym = [FCLispSymbol genSym:token.value];
    
    // if constant or reserved
    if (sym.type != FCLispSymbolTypeNormal) {
        return sym.value;
    }
    
    // return lisp symbol
    return sym;
}

- (id)getLispFloatNumberWithToken:(FCLispParserToken *)token
{
    // create a lisp float number
    return [FCLispNumber numberWithFloatValue:[token.value doubleValue]];
}

- (id)getLispIntegerNumberWithToken:(FCLispParserToken *)token
{
    // create a lisp integer number
    return [FCLispNumber numberWithIntegerValue:[token.value longLongValue]];
}

- (id)getLispStringWithToken:(FCLispParserToken *)token
{
    // create a lisp string
    return [FCLispString stringWithString:token.value];
}

//- (id)getLispQuoteList
//{
//    FCLispListBuilder *listBuilder = [FCLispListBuilder listBuilder];
//    
//    // add quote symbol as first entry in list
//    [listBuilder addCar:[_environment addSymbolWithName:@"quote"]];
//    
//    // get quoted value
//    id value = [self getLispObject];
//    
//    if (!value) {
//        // empty quote
//        NSString *reason = @"Empty quote";
//        NSException *exception = [NSException exceptionWithName:@"INTERPRETER quote"
//                                                         reason:reason
//                                                       userInfo:nil];
//        @throw exception;
//    }
//    
//    [listBuilder addCar:value];
//    
//    id returnValue = listBuilder.list;
//    
//    return returnValue;
//}
//
//- (id)getLispList
//{
//    FCLispListBuilder *listBuilder = [FCLispListBuilder listBuilder];
//    BOOL dotted = NO;
//    BOOL dottedValueSet = NO;
//    
//    while (YES) {
//        FCLispParserToken *token = [_parser getToken];
//        
//        if (!token) {
//            // no close parenthesis found to match open parenthesis
//            NSString *reason = @"Unmatched parenthesis";
//            NSException *exception = [NSException exceptionWithName:@"INTERPRETER list"
//                                                             reason:reason
//                                                           userInfo:nil];
//            @throw exception;
//        } else {
//            id value = nil;
//            
//            if (token.type == FCLispParserTokenTypeOpenList) {
//                // get new list value
//                value = [self getLispList];
//            } else if (token.type == FCLispParserTokenTypeCloseList) {
//                // close current list
//                break;
//            } else if (token.type == FCLispParserTokenTypeQuote) {
//                // get quoted value
//                value = [self getLispQuoteList];
//            } else if (token.type == FCLispParserTokenTypeSymbol) {
//                // get symbol value (symbol or reserved value)
//                value = [self getLispSymbolWithToken:token];
//            } else if (token.type == FCLispParserTokenTypeFloatNumber) {
//                value = [self getLispFloatNumberWithToken:token];
//            } else if (token.type == FCLispParserTokenTypeIntegerNumber) {
//                value = [self getLispIntegerNumberWithToken:token];
//            } else if (token.type == FCLispParserTokenTypeDot) {
//                // dotted list, double check if already dotted
//                if (dotted) {
//                    NSString *reason = @"Double dotted list";
//                    NSException *exception = [NSException exceptionWithName:@"INTERPRETER list"
//                                                                     reason:reason
//                                                                   userInfo:nil];
//                    @throw exception;
//                }
//                dotted = YES;
//            } else if (token.type == FCLispParserTokenTypeString) {
//                // create a lisp string
//                value = [self getLispStringWithToken:token];
//            }
//            
//            if (dotted) {
//                // if dotted, check if cdr is set
//                if (dottedValueSet) {
//                    NSString *reason = @"Dotted list cdr is already set";
//                    NSException *exception = [NSException exceptionWithName:@"INTERPRETER list"
//                                                                     reason:reason
//                                                                   userInfo:nil];
//                    @throw exception;
//                } else if (value) {
//                    // set cdr to value and set dottedValueSet to YES, don't allow dotted list cdr reassign
//                    dottedValueSet = YES;
//                    [listBuilder addCdr:value];
//                }
//            } else {
//                [listBuilder addCar:value];
//            }
//        }
//    }
//    
//    id returnValue = listBuilder.list;
//    
//    return returnValue;
//}
//
//- (id)getLispObject
//{
//    id value = nil;
//    FCLispParserToken *token = [_parser getToken];
//    
//    if (token) {
//        switch (token.type) {
//            case FCLispParserTokenTypeOpenList:
//                // get a list object
//                value = [self getLispList];
//                break;
//            case FCLispParserTokenTypeCloseList:
//                // unmatched close list token
//                {
//                    NSString *reason = @"Unmatched parenthesis";
//                    NSException *exception = [NSException exceptionWithName:@"INTERPRETER list"
//                                                                     reason:reason
//                                                                   userInfo:nil];
//                    @throw exception;
//                }
//                break;
//            case FCLispParserTokenTypeQuote:
//                // get quoted list
//                value = [self getLispQuoteList];
//                break;
//            case FCLispParserTokenTypeSymbol:
//                // get symbol (or reserved symbol value)
//                value = [self getLispSymbolWithToken:token];
//                break;
//            case FCLispParserTokenTypeFloatNumber:
//                value = [self getLispFloatNumberWithToken:token];
//                break;
//            case FCLispParserTokenTypeIntegerNumber:
//                value = [self getLispIntegerNumberWithToken:token];
//                break;
//            case FCLispParserTokenTypeDot:
//                // dot can only appear in list context
//                {
//                    NSString *reason = @"Dot found outside list context";
//                    NSException *exception = [NSException exceptionWithName:@"INTERPRETER dot"
//                                                                     reason:reason
//                                                                   userInfo:nil];
//                    @throw exception;
//                }
//                break;
//            case FCLispParserTokenTypeString:
//                // lisp string
//                value = [self getLispStringWithToken:token];
//                break;
//        }
//    }
//    
//    return value;
//}
//

// interpret parser tokens in given lisp environment
- (id)interpret
{
    return nil;
//    id returnValue = [FCLispNIL NIL];
//    
//    while (YES) {
//        id lispObject = [self getLispObject];
//        if (lispObject) {
//            returnValue = [_environment eval:lispObject];
//        } else {
//            break;
//        }
//    }
//    
//    return returnValue;
}

@end
