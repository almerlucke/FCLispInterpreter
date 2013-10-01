//
//  FCLispEnvironment.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/1/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCLispSymbol;

@interface FCLispEnvironment : NSObject

/**
 *  Get the default environment
 *
 *  @return environment object
 */
+ (FCLispEnvironment *)defaultEnvironment;

/**
 *  Generate a symbol, symbols SHOULD only be generated via gensym
 *
 *  @param name : symbol name
 *
 *  @return a new or existing symbol
 */
+ (FCLispSymbol *)genSym:(NSString *)name;

/**
 *  Register a class with the environment
 *
 *  @param theClass : MUST be a FCLispObject subclass
 */
+ (void)registerClass:(Class)theClass;

@end
