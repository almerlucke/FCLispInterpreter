//
//  NSArray+FCLispCons.h
//  Lisp
//
//  Created by aFrogleap on 12/12/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCLispCons;

@interface NSArray (FCLispCons)

/**
 *  Create an array from a FCLispCons object
 *
 *  @param cons
 *
 *  @return NSArray
 */
+ (NSArray *)arrayWithCons:(FCLispCons *)cons;

/**
 *  Create a FCLispCons from an array
 *
 *  @return FCLispCons
 */
- (FCLispCons *)cons;

@end
