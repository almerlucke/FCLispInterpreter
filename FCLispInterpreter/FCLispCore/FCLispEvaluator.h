//
//  FCLispEvaluator.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/8/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCLispObject;
@class FCLispScopeStack;

/**
 *  Evaluate Lisp objects, lookup symbol bindings in scope stack given
 */
@interface FCLispEvaluator : NSObject

/**
 *  Evaluate a Lisp object with a symbol scope stack
 *
 *  @param obj        FCLispObject to evaluate
 *  @param scopeStack Scope stack to evaluate symbols
 *
 *  @return FCLispObject
 */
+ (FCLispObject *)eval:(FCLispObject *)obj withScopeStack:(FCLispScopeStack *)scopeStack;

/**
 *  Setf-evaluate a Lisp object with a symbol scope stack
 *
 *  @param obj        FCLispObject to evaluate
 *  @param value      FClispObject to set
 *  @param scopeStack Scope stack to evaluate symbols
 *
 *  @return FClispObject
 */
+ (FCLispObject *)eval:(FCLispObject *)obj value:(FCLispObject *)value withScopeStack:(FCLispScopeStack *)scopeStack;

@end
