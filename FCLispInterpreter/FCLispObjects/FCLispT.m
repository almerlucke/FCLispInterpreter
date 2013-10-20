//
//  FCLispT.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispT.h"

@implementation FCLispT

#pragma mark - Init

+ (FCLispT *)T
{
    static FCLispT *sLispT = nil;
    static dispatch_once_t sDispatchOnce;
    
    dispatch_once(&sDispatchOnce, ^{
        sLispT = [[FCLispT alloc] init];
    });
    
    return sLispT;
}


#pragma mark - Description

- (NSString *)description
{
    return @"T";
}


#pragma mark - Encoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    return [FCLispT T];
}

@end
