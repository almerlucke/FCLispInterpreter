//
//  FCLispInterpreter.h
//  Lisp
//
//  Created by aFrogleap on 12/19/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCLispScopeStack;
@class FCLispParser;
@class FCLispObject;


/**
 *  Interpreter, interpret a stream of lisp tokens and evaluate them
 */
@interface FCLispInterpreter : NSObject

/**
 *  Interpret file at path
 *
 *  @param filePath
 *  @param scopeStack
 *
 *  @return FCLispObject
 */
+ (FCLispObject *)interpretFile:(NSString *)filePath withScopeStack:(FCLispScopeStack *)scopeStack;

/**
 *  Interpret NSData blob
 *
 *  @param data
 *  @param scopeStack
 *
 *  @return FCLispObject
 */
+ (FCLispObject *)interpretData:(NSData *)data withScopeStack:(FCLispScopeStack *)scopeStack;

/**
 *  Interpret NSString
 *
 *  @param string
 *  @param scopeStack
 *
 *  @return FCLispObject
 */
+ (FCLispObject *)interpretString:(NSString *)string withScopeStack:(FCLispScopeStack *)scopeStack;

@end
