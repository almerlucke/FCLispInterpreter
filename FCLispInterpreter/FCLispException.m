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

+ (NSString *)reasonFromType:(FCLispExceptionType)type
{
    NSString *reason = @"";
    
    switch (type) {
        case FCLispExceptionTypeOutOfMemory:
            reason = @"Out Of Memory";
            break;
        default:
            break;
    }
    
    return reason;
}

+ (FCLispException *)exceptionWithType:(FCLispExceptionType)type
{
    return [[FCLispException alloc] initWithName:[self exceptionName]
                                          reason:[self reasonFromType:type]
                                        userInfo:nil];
}

+ (FCLispException *)exceptionWithType:(FCLispExceptionType)type userInfo:(NSDictionary *)userInfo
{
    return [[FCLispException alloc] initWithName:[self exceptionName]
                                          reason:[self reasonFromType:type]
                                        userInfo:userInfo];
}

@end
