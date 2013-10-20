//
//  FCLispException.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 9/29/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>



/**
 *  Exception type
 */
typedef NS_ENUM(NSInteger, FCLispExceptionType)
{
    FCLispExceptionTypeOutOfMemory
};



/**
 *  Generic lisp exception class
 */
@interface FCLispException : NSException

@property (nonatomic) NSInteger exceptionType;

/**
 *  Create a lisp exception with type
 *
 *  @param type
 *
 *  @return FCLispException object to be thrown
 */
+ (FCLispException *)exceptionWithType:(NSInteger)type;

/**
 *  Create a lisp exception with type and user info
 *
 *  @param type
 *  @param userInfo
 *
 *  @return FCLispException object to be thrown
 */
+ (FCLispException *)exceptionWithType:(NSInteger)type userInfo:(NSDictionary *)userInfo;

/**
 *  Name for this exception (CAN be overwritten by subclasses)
 *
 *  @return exception name
 */
+ (NSString *)exceptionName;

/**
 *  Give a reason for a type and user info, CAN be used by subclasses to create reason strings with specific information
 *
 *  @param type
 *  @param userInfo
 *
 *  @return Reason string
 */
+ (NSString *)reasonForType:(NSInteger)type andUserInfo:(NSDictionary *)userInfo;

@end
