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

@interface FCLispInterpreter : NSObject

// parse and interpret lisp data in given environment
+ (FCLispObject *)interpretFile:(NSString *)filePath withScopeStack:(FCLispScopeStack *)scopeStack;
+ (FCLispObject *)interpretData:(NSData *)data withScopeStack:(FCLispScopeStack *)scopeStack;
+ (FCLispObject *)interpretString:(NSString *)string withScopeStack:(FCLispScopeStack *)scopeStack;

@end
