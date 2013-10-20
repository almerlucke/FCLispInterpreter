//
//  FCLispFunction.h
//  Lisp
//
//  Created by aFrogleap on 11/26/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//
//  Lisp Function Base Class
//

#import "FCLispObject.h"

@class FCLispCons;
@class FCLispScopeStack;


/**
 *  Lisp Function Base Class
 */
@interface FCLispFunction : FCLispObject

/**
 *  does the environment need to evaluate each arg first before passing it on
 */
@property (nonatomic) BOOL evalArgs;

/**
 *  Overwrite eval by subclasses to do something usefull with arguments
 *
 *  @param args       FCLispCons argument list
 *  @param scopeStack FCLispScopeStack symbol scope stack
 *
 *  @return FCLispObject
 */
- (FCLispObject *)eval:(FCLispCons *)args scopeStack:(FCLispScopeStack *)scopeStack;

@end
