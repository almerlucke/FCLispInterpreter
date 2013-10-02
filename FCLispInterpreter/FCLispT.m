//
//  FCLispT.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispT.h"

@implementation FCLispT

+ (FCLispT *)T
{
    static FCLispT *sLispT = nil;
    static dispatch_once_t sDispatchOnce;
    
    dispatch_once(&sDispatchOnce, ^{
        sLispT = [[FCLispT alloc] init];
    });
    
    return sLispT;
}

- (NSString *)description
{
    return @"T";
}

@end
