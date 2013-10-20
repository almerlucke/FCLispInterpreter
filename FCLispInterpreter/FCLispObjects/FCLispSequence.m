//
//  FCLispSequence.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/20/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispSequence.h"
#import "FCLispNIL.h"
#import "FCLispException.h"
#import "FCLispEnvironment.h"
#import "FCLispSymbol.h"
#import "FCLispBuildinFunction.h"
#import "FCLispCons.h"
#import "FCLispNumber.h"
#import "FCLispScopeStack.h"
#import "FCLispEvaluator.h"
#import "FCLispString.h"
#import "FCLispCharacter.h"


#pragma mark - FCLispSequence Exception

typedef NS_ENUM(NSInteger, FCLispSequenceExceptionType)
{
    FCLispSequenceExceptionTypeIndexOutOfBounds,
    FCLispSequenceExceptionTypeExpectedSequence,
    FCLispSequenceExceptionTypeExpectedIndex,
    FCLispSequenceExceptionTypeSetStringIndexWithNonCharacter
};

/**
 *  FClispSequenceException
 */
@interface FCLispSequenceException : FCLispException

@end

@implementation FCLispSequenceException

+ (NSString *)exceptionName
{
    return @"FCLispSequenceException";
}

+ (NSString *)reasonForType:(NSInteger)type andUserInfo:(NSDictionary *)userInfo
{
    NSString *reason = @"";
    
    switch (type) {
        case FCLispSequenceExceptionTypeIndexOutOfBounds: {
            NSNumber *index = [userInfo objectForKey:@"index"];
            FCLispSequence *sequence = [userInfo objectForKey:@"sequence"];
            reason = [NSString stringWithFormat:@"Index %@ out of bounds for sequence %@", index, sequence];
            break;
        }
        case FCLispSequenceExceptionTypeExpectedSequence: {
            FCLispObject *value = [userInfo objectForKey:@"value"];
            NSString *functionName = [userInfo objectForKey:@"functionName"];
            reason = [NSString stringWithFormat:@"%@ expected a sequence as first argument, %@ is not a sequence", functionName, value];
            break;
        }
        case FCLispSequenceExceptionTypeExpectedIndex: {
            FCLispObject *value = [userInfo objectForKey:@"value"];
            NSString *functionName = [userInfo objectForKey:@"functionName"];
            reason = [NSString stringWithFormat:@"%@ expected an index as second argument, %@ is not an integer", functionName, value];
            break;
        }
        case FCLispSequenceExceptionTypeSetStringIndexWithNonCharacter: {
            FCLispObject *value = [userInfo objectForKey:@"value"];
            reason = [NSString stringWithFormat:@"String sequence element at index can only be set with characters, %@ is not a character", value];
            break;
        }
        default:
            break;
    }
    
    return reason;
}

@end


#pragma mark - FCLispSequence

@implementation FCLispSequence

- (NSUInteger)length
{
    return 0;
}

- (FCLispObject *)objectAtIndex:(NSUInteger)index
{
    return [FCLispNIL NIL];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(FCLispObject *)anObject
{
    // do nothing
}

#pragma mark - Define Functions

+ (void)addGlobalBindingsToEnvironment:(FCLispEnvironment *)environment
{
    FCLispSymbol *global = nil;
    FCLispBuildinFunction *function = nil;
    
    // LENGTH
    global = [environment genSym:@"length"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionLength:) target:self];
    global.value = function;
    function.documentation = @"Get length of sequence (length sequence)";
    function.symbol = global;
    
    // ELT
    global = [environment genSym:@"elt"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionElt:) target:self evalArgs:YES canBeSet:YES];
    global.value = function;
    function.documentation = @"Get or set nth element of sequence (nth sequence index) or (= (nth sequence index) value)";
    function.symbol = global;
}


/**
 *  Get length of sequence object
 *
 *  @param callData
 *
 *  @return FCLispNumber respresenting length of sequence
 */
+ (FCLispObject *)buildinFunctionLength:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 1) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"LENGTH",
                                                               @"numExpected" : @1}];
    }
    
    FCLispSequence *sequence = (FCLispSequence *)args.car;
    if (![sequence isKindOfClass:[FCLispSequence class]]) {
        @throw [FCLispSequenceException exceptionWithType:FCLispSequenceExceptionTypeExpectedSequence
                                                 userInfo:@{@"functionName" : @"LENGTH",
                                                            @"value" : sequence}];
    }
    
    return [FCLispNumber numberWithIntegerValue:[sequence length]];
}

/**
 *  Get or set element at index of sequence
 *
 *  @param callData
 *
 *  @return
 */
+ (FCLispObject *)buildinFunctionElt:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    FCLispScopeStack *scopeStack = [callData objectForKey:@"scopeStack"];
    FCLispObject *setfValue = [callData objectForKey:@"value"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 2) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"ELT",
                                                               @"numExpected" : @2}];
    }
    
    FCLispSequence *sequence = (FCLispSequence *)args.car;
    if (![sequence isKindOfClass:[FCLispSequence class]]) {
        @throw [FCLispSequenceException exceptionWithType:FCLispSequenceExceptionTypeExpectedSequence
                                                 userInfo:@{@"functionName" : @"ELT",
                                                            @"value" : sequence}];
    }
    
    args = (FCLispCons *)args.cdr;
    
    FCLispNumber *number = (FCLispNumber *)args.car;
    if (![number isKindOfClass:[FCLispNumber class]] || number.numberType != FCLispNumberTypeInteger) {
        @throw [FCLispSequenceException exceptionWithType:FCLispSequenceExceptionTypeExpectedIndex
                                                 userInfo:@{@"functionName" : @"ELT",
                                                            @"value" : number}];
    }
    
    int64_t index = number.integerValue;
    NSUInteger length = [sequence length];
    
    if (index < 0 || index >= length) {
        @throw [FCLispSequenceException exceptionWithType:FCLispSequenceExceptionTypeIndexOutOfBounds
                                                 userInfo:@{@"sequence" : sequence,
                                                            @"index" : number}];
    }
    
    FCLispObject *returnValue = [FCLispNIL NIL];
    
    if (setfValue) {
        returnValue = [FCLispEvaluator eval:setfValue withScopeStack:scopeStack];
        if ([sequence isKindOfClass:[FCLispString class]] && ![returnValue isKindOfClass:[FCLispCharacter class]]) {
            @throw [FCLispSequenceException exceptionWithType:FCLispSequenceExceptionTypeSetStringIndexWithNonCharacter
                                                     userInfo:@{@"value" : returnValue}];
        } else {
            [sequence replaceObjectAtIndex:index withObject:returnValue];
        }
    } else {
        returnValue = [sequence objectAtIndex:index];
    }
 
    return returnValue;
}

@end