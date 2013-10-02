//
//  FCLispT.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispObject.h"

/**
 *  Lisp T object
 */
@interface FCLispT : FCLispObject

/**
 *  Singleton T object
 *
 *  @return T
 */
+ (FCLispT *)T;

@end
