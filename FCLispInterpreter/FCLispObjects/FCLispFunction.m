//
//  FCLispFunction.m
//  Lisp
//
//  Created by aFrogleap on 11/26/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "FCLispFunction.h"
#import "FCLispNIL.h"

@implementation FCLispFunction

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        self.evalArgs = [aDecoder decodeBoolForKey:@"evalArgs"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeBool:self.evalArgs forKey:@"evalArgs"];
}

- (FCLispObject *)eval:(FCLispCons *)args scopeStack:(FCLispScopeStack *)scopeStack
{
    // STUB does nothing
    
    return [FCLispNIL NIL];
}

@end
