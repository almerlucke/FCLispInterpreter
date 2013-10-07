//
//  FCLispNumber.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispNumber.h"

/**
 *  Number type
 */
typedef enum
{
    FCLispNumberTypeInteger = 0,
    FCLispNumberTypeFloat = 1
//    FCLispNumberTypeRatio = 2
} FCLispNumberType;


/**
 *  Number value union
 */
typedef union
{
    double floatValue;
    int64_t integerValue;
} FCLispNumberUnion;



/**
 *  Private number interface
 */
@interface FCLispNumber ()
{
    FCLispNumberType _type;
    FCLispNumberUnion _valueUnion;
}
@end


@implementation FCLispNumber

- (id)initWithFloatValue:(double)floatValue
{
    if ((self = [super init])) {
        _type = FCLispNumberTypeFloat;
        _valueUnion.floatValue = floatValue;
    }
    
    return self;
}

- (id)initWithIntegerValue:(int64_t)integerValue
{
    if ((self = [super init])) {
        _type = FCLispNumberTypeInteger;
        _valueUnion.integerValue = integerValue;
    }
    
    return self;
}

+ (FCLispNumber *)numberWithIntegerValue:(int64_t)integerValue
{
    return [[self alloc] initWithIntegerValue:integerValue];
}

+ (FCLispNumber *)numberWithFloatValue:(double)floatValue
{
    return [[self alloc] initWithFloatValue:floatValue];
}

- (NSString *)description
{
    NSString *desc = @"";
    
    if (_type == FCLispNumberTypeInteger) desc = [NSString stringWithFormat:@"%lld", _valueUnion.integerValue];
    else if (_type == FCLispNumberTypeFloat) desc = [NSString stringWithFormat:@"%lf", _valueUnion.floatValue];
    
    return desc;
}

@end
