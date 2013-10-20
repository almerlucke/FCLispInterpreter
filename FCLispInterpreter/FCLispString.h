//
//  FCLispString.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispSequence.h"

/**
 *  Lisp string object
 */
@interface FCLispString : FCLispSequence

/**
 *  NSString string
 */
@property (nonatomic, readonly) NSString *string;

/**
 *  Create a new lisp string
 *
 *  @param string
 *
 *  @return FCLispString object
 */
+ (FCLispString *)stringWithString:(NSString *)string;

@end
