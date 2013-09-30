//
//  FCLispException.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 9/29/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispException.h"

@implementation FCLispException

+ (NSString *)exceptionName
{
    return @"FCLispException";
}

+ (NSString *)reasonForType:(NSInteger)type andUserInfo:(NSDictionary *)userInfo
{
    NSString *reason = @"";
    
    switch (type) {
        case FCLispExceptionTypeOutOfMemory:
            reason = @"Out of memory";
            break;
        default:
            break;
    }
    
    return reason;
}

+ (FCLispException *)exceptionWithType:(NSInteger)type
{
    return [[FCLispException alloc] initWithName:[self exceptionName]
                                          reason:[self reasonForType:type andUserInfo:nil]
                                        userInfo:nil];
}

+ (FCLispException *)exceptionWithType:(NSInteger)type userInfo:(NSDictionary *)userInfo
{
    return [[FCLispException alloc] initWithName:[self exceptionName]
                                          reason:[self reasonForType:type andUserInfo:userInfo]
                                        userInfo:userInfo];
}

@end
