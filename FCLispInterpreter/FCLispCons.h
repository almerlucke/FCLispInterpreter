//
//  FCList.h
//  Lisp
//
//  Created by aFrogleap on 11/26/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "FCLispObject.h"


/**
 *  Lisp cons respresentation.
 *  A cons has a car and a cdr, the car part is usually the value and the cdr part is usually a ptr to the next cons
 *  kind of like a linked list.
 */
@interface FCLispCons : FCLispObject
/**
 *  Car of cons
 */
@property (nonatomic, strong) FCLispObject *car;

/**
 *  Cdr of cons
 */
@property (nonatomic, strong) FCLispObject *cdr;

/**
 *  Initialize a cons with a car and cdr
 *
 *  @param car
 *  @param cdr
 *
 *  @return FCLispCons object
 */
- (id)initWithCar:(FCLispObject *)car andCdr:(FCLispObject *)cdr;

/**
 *  Create a cons with a car and cdr
 *
 *  @param car
 *  @param cdr
 *
 *  @return FCLispCons object
 */
+ (FCLispCons *)consWithCar:(FCLispObject *)car andCdr:(FCLispObject *)cdr;

/**
 *  Get the length of this cons list
 *
 *  @return Length of list
 */
- (NSInteger)length;

@end