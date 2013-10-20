//
//  FCLispNumber.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispObject.h"

/**
 *  Number type
 */
typedef NS_ENUM(NSInteger, FCLispNumberType)
{
    FCLispNumberTypeInteger = 0,
    FCLispNumberTypeFloat = 1
    //    FCLispNumberTypeRatio = 2
};


@interface FCLispNumber : FCLispObject

/**
 *  Get the type of number
 */
@property (nonatomic, readonly) FCLispNumberType numberType;

/**
 *  Get integer value from number
 */
@property (nonatomic, readonly) int64_t integerValue;

/**
 *  Get float value from number
 */
@property (nonatomic, readonly) double floatValue;


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
