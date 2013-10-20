//
//  FCLispObject.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/1/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispObject.h"

@implementation FCLispObject

+ (void)addGlobalBindingsToEnvironment:(FCLispEnvironment *)environment
{
    // do nothing
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    // do nothing
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super init])) {
        
    }
    
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] init];
}

@end
