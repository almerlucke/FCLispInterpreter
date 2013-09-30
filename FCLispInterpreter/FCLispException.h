//
//  FCLispException.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 9/29/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, FCLispExceptionType)
{
    FCLispExceptionTypeOutOfMemory
};

@interface FCLispException : NSException

+ (FCLispException *)exceptionWithType:(NSInteger)type;
+ (FCLispException *)exceptionWithType:(NSInteger)type userInfo:(NSDictionary *)userInfo;

+ (NSString *)exceptionName;
+ (NSString *)reasonForType:(NSInteger)type andUserInfo:(NSDictionary *)userInfo;

@end
