//
//  FCLispListBuilder.m
//  Lisp
//
//  Created by aFrogleap on 12/12/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "FCLispListBuilder.h"
#import "FCLispCons.h"
#import "FCLispNIL.h"


@interface FCLispListBuilder ()
{
    FCLispCons *_head;
    FCLispCons *_tail;
}
@end

@implementation FCLispListBuilder


#pragma mark - Init

- (id)init
{
    if ((self = [super init])) {
        _head = nil;
        _tail = nil;
    }
    
    return self;
}

+ (FCLispListBuilder *)listBuilder
{
    return [[FCLispListBuilder alloc] init];
}


#pragma mark - Build

- (void)addCar:(id)car
{
    FCLispCons *newCons = [FCLispCons consWithCar:car andCdr:[FCLispNIL NIL]];
    
    [self addCdr:newCons];
}

- (void)addCdr:(id)cdr
{
    if ([cdr isKindOfClass:[FCLispCons class]]) {
        if (_tail) {
            // if tail.cdr is nil we add a ref to the new cons and set tail to cons, otherwise we do nothing
            if (_tail.cdr == [FCLispNIL NIL]) {
                _tail.cdr = cdr;
                _tail = cdr;
            }
        } else {
            // set tail to new cons
            _tail = cdr;
        }
        
        // if head does not exist yet set it to the first cons we create
        if (!_head) {
            _head = cdr;
        }
    } else if (_tail) {
        // cdr is not a cons, so we set tail.cdr to the lisp object (creating a dotted/unpure list)
        _tail.cdr = cdr;
    }
}

- (FCLispCons *)lispList
{
    if (!_head) {
        return (FCLispCons *)[FCLispNIL NIL];
    }
    
    return _head;
}

- (FCLispCons *)list
{
    return _head;
}

@end
