//
//  FCLispEvaluator.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/8/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispEvaluator.h"
#import "FCLispObject.h"
#import "FCLispCons.h"
#import "FCLispListBuilder.h"
#import "FCLispEnvironment.h"
#import "FCLispSymbol.h"
#import "FCLispScopeStack.h"
#import "FCLispFunction.h"
#import "FCLispBuildinFunction.h"


@implementation FCLispEvaluator

#pragma mark - Evaluate

+ (FCLispObject *)evalSymbol:(FCLispSymbol *)symbol withScopeStack:(FCLispScopeStack *)scopeStack
{
    // first take a look at local variable stack, see if we have a local variable defined
    FCLispObject *returnValue = [scopeStack bindingForSymbol:symbol];
    
    if (!returnValue) {
        // no local variable on stack so we look if there is a global value
        returnValue = symbol.value;
        if (!returnValue) {
            // unbound variable so raise an error
            NSString *reason = [NSString stringWithFormat:@"Unbound variable %@", symbol.name];
            NSException *exception = [NSException exceptionWithName:@"Eval exception"
                                                             reason:reason
                                                           userInfo:nil];
            @throw exception;
        }
    }
    
    return returnValue;
}

+ (FCLispObject *)evalCons:(FCLispCons *)cons withScopeStack:(FCLispScopeStack *)scopeStack
{
    FCLispObject *returnValue = nil;
    
    // first evaluate car of first cons to get function value
    FCLispFunction *fun = (FCLispFunction *)[self eval:cons.car withScopeStack:scopeStack];
    
    if ([fun isKindOfClass:[FCLispFunction class]]) {
        FCLispListBuilder *listBuilder = [FCLispListBuilder listBuilder];
        
        // first skip to next cons (we used first cons to get function value)
        FCLispCons *args = (FCLispCons *)cons.cdr;
        
        // check if we need to evaluate args first
        if (fun.evalArgs) {
            // evaluate all function arguments and build the arg list
            while ([args isKindOfClass:[FCLispCons class]]) {
                [listBuilder addCar:[self eval:args.car withScopeStack:scopeStack]];
                args = (FCLispCons *)args.cdr;
            }
            args = [listBuilder lispList];
        }
        
        // evaluate function with args and environment
        returnValue = [fun eval:args scopeStack:scopeStack];
    } else {
        NSString *reason = [NSString stringWithFormat:@"Funcall of %@ which is a non-function.", fun];
        NSException *exception = [NSException exceptionWithName:@"Eval exception"
                                                         reason:reason
                                                       userInfo:nil];
        @throw exception;
    }
    
    return returnValue;
}

+ (FCLispObject *)eval:(FCLispObject *)obj withScopeStack:(FCLispScopeStack *)scopeStack
{
    // all objects which are not conses or symbols return themselves when evaluated
    FCLispObject *returnValue = obj;
    
    if ([obj isKindOfClass:[FCLispSymbol class]]) {
        // evaluate symbol
        returnValue = [self evalSymbol:(FCLispSymbol *)obj withScopeStack:scopeStack];
    } else if ([obj isKindOfClass:[FCLispCons class]]) {
        // evaluate cons
        returnValue = [self evalCons:(FCLispCons *)obj withScopeStack:scopeStack];
    }
    
    return returnValue;
}

+ (FCLispObject *)eval:(FCLispObject *)obj value:(FCLispObject *)value withScopeStack:(FCLispScopeStack *)scopeStack
{
    id returnValue = nil;
    NSString *reason = [NSString stringWithFormat:@"SETF argument %@ can not be set", obj];
    NSException *setfEvalException = [NSException exceptionWithName:@"SETF exception"
                                                             reason:reason
                                                           userInfo:nil];
    
    if ([obj isKindOfClass:[FCLispCons class]]) {
        FCLispCons *cons = (FCLispCons *)obj;
        
        // first evaluate car of first cons to get buildin function value
        FCLispBuildinFunction *fun = (FCLispBuildinFunction *)[self eval:cons.car withScopeStack:scopeStack];
        
        // check if function is buildin function and can be set by setf
        if ([fun isKindOfClass:[FCLispBuildinFunction class]] && fun.canBeSet) {
            FCLispListBuilder *listBuilder = [FCLispListBuilder listBuilder];
            
            // first skip to next cons (we used first cons to get function value)
            FCLispCons *args = (FCLispCons *)cons.cdr;
            
            // check if we need to evaluate args first
            if (fun.evalArgs) {
                // evaluate all function arguments and build the arg list
                while ([args isKindOfClass:[FCLispCons class]]) {
                    [listBuilder addCar:[self eval:args.car withScopeStack:scopeStack]];
                    args = (FCLispCons *)args.cdr;
                }
                args = [listBuilder lispList];
            }
            
            // evaluate buildin function with args, setf value and environment
            returnValue = [fun eval:args value:value scopeStack:scopeStack];
        } else {
            @throw setfEvalException;
        }
    } else {
        @throw setfEvalException;
    }
    
    return returnValue;
}

@end
