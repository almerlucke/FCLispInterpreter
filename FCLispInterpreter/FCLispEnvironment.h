//
//  FCLispEnvironment.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/1/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCLispException.h"

@class FCLispSymbol;
@class FCLispScopeStack;
@class FCLispObject;



/**
 *  Lisp environment error types
 */
typedef NS_ENUM(NSInteger, FCLispEnvironmentExceptionType)
{
    FCLispEnvironmentExceptionTypeNumArguments,
    FCLispEnvironmentExceptionTypeAssignmentToReservedSymbol,
    FCLispEnvironmentExceptionTypeAssignmentToUnboundSymbol,
    FCLispEnvironmentExceptionTypeBreak,
    FCLispEnvironmentExceptionTypeReturn,
    FCLispEnvironmentExceptionTypeIllegalLambdaParamList,
    FCLispEnvironmentExceptionTypeLambdaParamListContainsNonSymbol,
    FCLispEnvironmentExceptionTypeLambdaParamOverwriteReservedSymbol,
    FCLispEnvironmentExceptionTypeDefineExpectedSymbol,
    FCLispEnvironmentExceptionTypeDefineCanNotOverwriteSymbol,
    FCLispEnvironmentExceptionTypeLetExpectedVariableList,
    FCLispEnvironmentExceptionTypeLetParamOverwriteReservedSymbol,
    FCLispEnvironmentExceptionTypeIllegalLetVariable,
    FCLispEnvironmentExceptionTypeSerializeExpectedPath,
    FCLispEnvironmentExceptionTypeDeserializeExpectedPath,
    FCLispEnvironmentExceptionTypeLoadExpectedPath
};

/**
 *  FClispEnvironmentException
 */
@interface FCLispEnvironmentException : FCLispException

@end




/**
 *  The main lisp environment, holds symbols, and main thread scope stack
 */
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
 *  @param name Symbol name
 *
 *  @return a new or existing symbol
 */
+ (FCLispSymbol *)genSym:(NSString *)name;

/**
 *  Generate a symbol, symbols SHOULD only be generated via gensym
 *
 *  @param name Symbol name
 *
 *  @return a new or existing symbol
 */
- (FCLispSymbol *)genSym:(NSString *)name;

/**
 *  Register a class with the default environment
 *
 *  @param theClass MUST be a FCLispObject subclass
 */
+ (void)registerClass:(Class)theClass;

/**
 *  Serialize the environment to NSData blob. Serialization is not perfect. 
 *  Two lambda functions which have caught the same scope stack will end up after deserialize,
 *  with two different scope stacks, because the pointer is not the same any more.
 *  Also defined global variables are stored in symbol.value, type and value are not stored when
 *  serializing symbols. So defined variables are lost after deserialization.
 *
 *  @return NSData
 */
+ (NSData *)serialize;

/**
 *  Deserialize the environment from NSData blob
 *
 *  @param data
 */
+ (void)deserialize:(NSData *)data;

/**
 *  Main thread scope stack
 *
 *  @return FCLispScopeStack object
 */
+ (FCLispScopeStack *)mainScopeStack;

/**
 *  Throw a break exception
 */
+ (void)throwBreakException;

/**
 *  Throw a return exception
 *
 *  @param value
 */
+ (void)throwReturnExceptionWithValue:(FCLispObject *)value;

@end
