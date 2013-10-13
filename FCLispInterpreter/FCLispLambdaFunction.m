//
//  FCLispLambdaFunction.m
//  Lisp
//
//  Created by aFrogleap on 12/14/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "FCLispLambdaFunction.h"
#import "FCLispNIL.h"
#import "FCLispCons.h"
#import "FCLispSymbol.h"
#import "FCLispEnvironment.h"
#import "FCLispScopeStack.h"
#import "FCLispObject.h"
#import "FCLispEvaluator.h"
#import "FCLispException.h"

#pragma mark - FClispLambaException

/**
 *  FCLispLambdaExceptionType
 */
typedef NS_ENUM(NSInteger, FCLispLambdaExceptionType)
{
    FCLispLambdaExceptionTypeNumArguments
};

/**
 *  FClispLambdaException
 */
@interface FCLispLambdaException : FCLispException

@end

@implementation FCLispLambdaException

+ (NSString *)exceptionName
{
    return @"FCLispLambdaException";
}

+ (NSString *)reasonForType:(NSInteger)type andUserInfo:(NSDictionary *)userInfo
{
    NSString *reason = @"";
    
    switch (type) {
        case FCLispLambdaExceptionTypeNumArguments: {
            FCLispLambdaFunction *lambdaFunction = [userInfo objectForKey:@"lambdaFunction"];
            NSNumber *numExpected = [userInfo objectForKey:@"numExpected"];
            reason = [NSString stringWithFormat:@"%@ expected at least %@ argument(s)", lambdaFunction, numExpected];
            break;
        }
        default:
            break;
    }
    
    return reason;
}

@end



#pragma mark - FCLispLambdaFunction

@implementation FCLispLambdaFunction

- (id)init
{
    if ((self = [super init])) {
        self.evalArgs = YES;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        self.params = [aDecoder decodeObjectForKey:@"params"];
        self.body = [aDecoder decodeObjectForKey:@"body"];
        self.capturedScopeStack = [aDecoder decodeObjectForKey:@"scopeStack"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.params forKey:@"params"];
    [aCoder encodeObject:self.body forKey:@"body"];
    [aCoder encodeObject:self.capturedScopeStack forKey:@"scopeStack"];
}

- (FCLispObject *)eval:(FCLispCons *)args scopeStack:(FCLispScopeStack *)scopeStack
{
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < [self.params count]) {
        @throw [FCLispLambdaException exceptionWithType:FCLispLambdaExceptionTypeNumArguments
                                               userInfo:@{@"lambdaFunction": self,
                                                          @"numExpected" : [NSNumber numberWithInteger:[self.params count]]}];
    }
    
    // push captured scope stack
    [scopeStack pushScopeStack:self.capturedScopeStack];
    
    // push new scope for params given
    [scopeStack pushScope:nil];
    
    // add local variables on the new scope
    for (FCLispSymbol *sym in self.params) {
        [scopeStack addBinding:args.car forSymbol:sym];
        args = (FCLispCons *)args.cdr;
    }
    
    // add &REST local variable
    FCLispSymbol *andRestSym = [FCLispSymbol genSym:@"&rest"];
    
    // check if we have any &rest args
    if ([args isKindOfClass:[FCLispCons class]]) {
        // push rest of arg list to &REST local variable
        [scopeStack addBinding:args forSymbol:andRestSym];
    } else {
        // push NIL to &REST symbol local variable stack
        [scopeStack addBinding:[FCLispNIL NIL] forSymbol:andRestSym];
    }
    
    // define cleanup block
    void (^cleanupBlock)() = ^{
        // pop local scope
        [scopeStack popScope];
        
        // pop captured scope stack
        [scopeStack popScopeStack:self.capturedScopeStack];
    };
    
    // NIL is default return value
    FCLispObject *returnValue = [FCLispNIL NIL];
    
    // eval body in try/catch block to be able to cleanup if something exceptional happens
    @try {
        // evaluate body elements in sequence
        for (FCLispObject *obj in self.body) {
            returnValue = [FCLispEvaluator eval:obj withScopeStack:scopeStack];
        }
    }
    @catch (FCLispException *exception) {
        // check if we caught a return exception
        if ([exception.name isEqualToString:[FCLispEnvironmentException exceptionName]] &&
            exception.exceptionType == FCLispEnvironmentExceptionTypeReturn) {
            
            // assign return value to value got from return exception
            returnValue = [exception.userInfo objectForKey:@"value"];
        } else {
            // clean up local variables
            cleanupBlock();
            // throw exception further down the line
            @throw exception;
        }
    }
    @catch (NSException *exception) {
        // clean up local variables
        cleanupBlock();
        // throw exception further down the line
        @throw exception;
    }
    
    // clean up local variables
    cleanupBlock();

    return returnValue;
}

@end
