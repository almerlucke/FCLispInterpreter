//
//  FCLispSymbol.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/1/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispObject.h"


/**
 *  Symbols are first class lisp objects, but can also represent variable bindings
 */
@interface FCLispSymbol : FCLispObject

/**
 *  Name of symbol (read-only)
 */
@property (nonatomic, readonly) NSString *name;

/**
 *  New symbols should be created via genSym, the only one calling this method should be FCLispEnvironment
 *
 *  @param name The symbol name (is converted to uppercase)
 *
 *  @return symbol object
 */
- (id)initWithName:(NSString *)name;

/**
 *  Generate a symbol, this method is redirected to FCLispEnvironment genSym
 *
 *  @param name The symbol name (is converted to uppercase)
 *
 *  @return symbol object
 */
+ (FCLispSymbol *)genSym:(NSString *)name;

@end
