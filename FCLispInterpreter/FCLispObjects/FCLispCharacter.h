//
//  FCLispCharacter.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/20/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispObject.h"

@class FCUTF8Char;

@interface FCLispCharacter : FCLispObject

/**
 *  Get internal FCUTF8Char object
 */
@property (nonatomic, readonly) FCUTF8Char *character;

/**
 *  Initialize with FCUTF8Char
 *
 *  @param character
 *
 *  @return FCLispCharacter
 */
- (id)initWithUTF8Char:(FCUTF8Char *)character;

/**
 *  Class wrapper around initWithUTF8Char
 *
 *  @param character
 *
 *  @return FCLispCharacter
 */
+ (FCLispCharacter *)characterWithUTF8Char:(FCUTF8Char *)character;

@end
