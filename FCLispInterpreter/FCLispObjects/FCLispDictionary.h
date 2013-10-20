//
//  FCLispDictionary.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/19/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispObject.h"

@interface FCLispDictionary : FCLispObject

/**
 *  Read-only dictionary representation
 */
@property (nonatomic, readonly) NSMutableDictionary *dictionary;

/**
 *  Initialize with NSDictionary
 *
 *  @param dictionary
 *
 *  @return FCLispDictionary
 */
- (id)initWithDictionary:(NSDictionary *)dictionary;

/**
 *  Class wrapper around initWithDictionary
 *
 *  @param dictionary
 *
 *  @return FCLispDictionary
 */
+ (FCLispDictionary *)dictionaryWithDictionary:(NSDictionary *)dictionary;

@end
