//
//  FCLispSymbol.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/1/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispObject.h"

typedef NS_ENUM(NSInteger, FCLispSymbolType)
{
    FCLispSymbolTypeNormal = 0,
    FCLispSymbolTypeLiteral = 1,
    FCLispSymbolTypeConstant = 2,
    FCLispSymbolTypeBuildin = 3,
    FCLispSymbolTypeReserved = 4,
    FCLispSymbolTypeDefined = 5
};

/**
 *  Symbols are first class lisp objects, but can also represent variable bindings
 */
@interface FCLispSymbol : FCLispObject

/**
 *  Name of symbol (read-only)
 */
@property (nonatomic, readonly) NSString *name;

/**
 *  Symbol type (to specify reserved symbols for instance)
 */
@property (nonatomic) FCLispSymbolType type;

/**
 *  Reserved or constant value
 */
@property (nonatomic, strong) FCLispObject *value;

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
