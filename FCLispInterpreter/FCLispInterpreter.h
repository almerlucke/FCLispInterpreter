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

@interface FCLispInterpreter : NSObject

// parse and interpret lisp data in given environment
+ (id)interpretFile:(NSString *)filePath withScopeStack:(FCLispScopeStack *)scopeStack;
+ (id)interpretData:(NSData *)data withScopeStack:(FCLispScopeStack *)scopeStack;
+ (id)interpretString:(NSString *)string withScopeStack:(FCLispScopeStack *)scopeStack;

@end
