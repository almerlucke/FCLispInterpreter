//
//  FCLispString.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispObject.h"

/**
 *  Lisp string object
 */
@interface FCLispString : FCLispObject

/**
 *  NSString string
 */
@property (nonatomic, copy) NSString *string;

@end
