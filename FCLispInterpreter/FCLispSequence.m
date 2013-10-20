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


#pragma mark - FCLispSequence Exception

typedef NS_ENUM(NSInteger, FCLispSequenceExceptionType)
{
    FCLispSequenceExceptionTypeIndexOutOfBounds,
    FCLispSequenceExceptionTypeExpectedSequence
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
            reason = [NSString stringWithFormat:@"%@ expected a sequence, %@ is not a sequence", functionName, value];
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

@end