//
//  NSArray+FCLispCons.m
//  Lisp
//
//  Created by aFrogleap on 12/12/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "NSArray+FCLisp.h"
#import "FCLispCons.h"
#import "FCLispListBuilder.h"

@implementation NSArray (FCLispCons)

+ (NSArray *)arrayWithCons:(FCLispCons *)cons
{
    NSMutableArray *consArray = [NSMutableArray array];
    
    while ([cons isKindOfClass:[FCLispCons class]]) {
        [consArray addObject:cons.car];
        cons = (FCLispCons *)cons.cdr;
    }
    
    return [NSArray arrayWithArray:consArray];
}

- (FCLispCons *)cons
{
    FCLispListBuilder *listBuilder = [FCLispListBuilder listBuilder];
    
    for (id obj in self) {
        [listBuilder addCar:obj];
    }
    
    return [listBuilder lispList];
}

@end
