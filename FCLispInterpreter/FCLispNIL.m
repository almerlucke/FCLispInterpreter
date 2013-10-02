//
//  FCLispNIL.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispNIL.h"

@implementation FCLispNIL

+ (FCLispNIL *)NIL
{
    static FCLispNIL *sLispNIL = nil;
    static dispatch_once_t sDispatchOnce;
    
    dispatch_once(&sDispatchOnce, ^{
        sLispNIL = [[FCLispNIL alloc] init];
    });
    
    return sLispNIL;
}

- (NSString *)description
{
    return @"NIL";
}

@end
