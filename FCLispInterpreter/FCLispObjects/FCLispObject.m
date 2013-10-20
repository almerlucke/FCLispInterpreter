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

@end
