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
    FCLispExceptionTypeOutOfMemory = -1
};

@interface FCLispException : NSException
+ (FCLispException *)exceptionWithType:(FCLispExceptionType)type;
+ (FCLispException *)exceptionWithType:(FCLispExceptionType)type userInfo:(NSDictionary *)userInfo;
@end
