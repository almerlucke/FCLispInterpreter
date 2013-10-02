//
//  FCLispNumber.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispObject.h"

@interface FCLispNumber : FCLispObject

/**
 *  Create a lisp number with a double value
 *
 *  @param floatValue
 *
 *  @return FCLispNumber object
 */
+ (FCLispNumber *)numberWithFloatValue:(double)floatValue;

/**
 *  Create a lisp number with an integer value
 *
 *  @param integerValue
 *
 *  @return FCLispNumber object
 */
+ (FCLispNumber *)numberWithIntegerValue:(int64_t)integerValue;

@end
