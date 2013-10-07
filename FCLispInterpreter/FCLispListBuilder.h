//
//  FCLispListBuilder.h
//  Lisp
//
//  Created by aFrogleap on 12/12/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCLispCons;
@class FCLispObject;

@interface FCLispListBuilder : NSObject

/**
 *  Create a new listbuilder object
 *
 *  @return FCLispListBuilder object
 */
+ (FCLispListBuilder *)listBuilder;


#pragma mark - Build

/**
 *  Add a car to the list
 *
 *  @param car
 */
- (void)addCar:(FCLispObject *)car;

/**
 *  Add a cdr to the list (if obj is not a FCLispCons and not FCLispNIL, then we create an unpure list)
 *
 *  @param cdr
 */
- (void)addCdr:(FCLispObject *)cdr;

/**
 *  Get a FCLispCons list, if the list is empty return FCLispNIL
 *
 *  @return FCLispCons object or FCLispNIL
 */
- (FCLispCons *)lispList;

/**
 *  Get a FCLispCons list, if the list is empty return nil
 *
 *  @return FCLispCons object or nil
 */
- (FCLispCons *)list;

@end
