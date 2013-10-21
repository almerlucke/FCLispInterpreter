//
//  FCLispArray.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/21/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispArray.h"
#import "FCLispSymbol.h"
#import "FCLispBuildinFunction.h"
#import "FCLispEnvironment.h"
#import "FCLispCons.h"


@interface FCLispArray ()
{
    NSMutableArray *_array;
}
@end


@implementation FCLispArray

#pragma mark - Init

- (id)initWithArray:(NSArray *)array
{
    if ((self = [super init])) {
        _array = [array mutableCopy];
    }
    
    return self;
}

+ (FCLispArray *)arrayWithArray:(NSArray *)array
{
    return [[[self class] alloc] initWithArray:array];
}


#pragma mark - Encoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _array = [aDecoder decodeObjectForKey:@"array"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_array forKey:@"array"];
}


#pragma mark - Copying

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithArray:_array];
}


#pragma mark - Description

- (NSString *)description
{
    NSMutableString *str = [NSMutableString string];
    
    [str appendString:@"["];
    BOOL first = YES;
    
    for (FCLispObject *obj in _array) {
        if (first) {
            [str appendFormat:@"%@", obj];
            first = NO;
        } else {
            [str appendFormat:@" %@", obj];
        }
    }
    
    [str appendString:@"]"];
    
    return str;
}


#pragma mark - FCLispSequence

- (NSUInteger)length
{
    return [_array count];
}

- (FCLispObject *)objectAtIndex:(NSUInteger)index
{
    return [_array objectAtIndex:index];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(FCLispObject *)anObject
{
    [_array replaceObjectAtIndex:index withObject:anObject];
}


#pragma mark - Build in functions

+ (void)addGlobalBindingsToEnvironment:(FCLispEnvironment *)environment
{
    FCLispSymbol *global = nil;
    FCLispBuildinFunction *function = nil;
    
    // ARRAY
    global = [environment genSym:@"array"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionArray:) target:self evalArgs:YES];
    global.value = function;
    function.documentation = @"Create an array (ARRAY &rest elements).\n";
    function.symbol = global;
}

/**
 *  Create a lisp array
 *
 *  @param callData
 *
 *  @return FCLispArray
 */
+ (FCLispObject *)buildinFunctionArray:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    NSMutableArray *array = [NSMutableArray array];
    
    while ([args isKindOfClass:[FCLispCons class]]) {
        [array addObject:args.car];
        args = (FCLispCons *)args.cdr;
    }
    
    return [FCLispArray arrayWithArray:array];
}

@end
