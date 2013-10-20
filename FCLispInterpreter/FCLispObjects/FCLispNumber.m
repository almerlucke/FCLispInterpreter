//
//  FCLispNumber.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispNumber.h"




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

- (FCLispNumberType)numberType
{
    return _type;
}

- (int64_t)integerValue
{
    return _valueUnion.integerValue;
}

- (double)floatValue
{
    return _valueUnion.floatValue;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeInteger:_type forKey:@"type"];
    if (_type == FCLispNumberTypeInteger) {
        [aCoder encodeInt64:_valueUnion.integerValue forKey:@"integer"];
    } else if (_type == FCLispNumberTypeFloat) {
        [aCoder encodeDouble:_valueUnion.floatValue forKey:@"float"];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _type = [aDecoder decodeIntegerForKey:@"type"];
        if (_type == FCLispNumberTypeInteger) {
            _valueUnion.integerValue = [aDecoder decodeInt64ForKey:@"integer"];
        } else if (_type == FCLispNumberTypeFloat) {
            _valueUnion.floatValue = [aDecoder decodeDoubleForKey:@"float"];
        }
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
