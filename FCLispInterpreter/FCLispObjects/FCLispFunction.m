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

#pragma mark - Encoding

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


#pragma mark - Eval

- (FCLispObject *)eval:(FCLispCons *)args scopeStack:(FCLispScopeStack *)scopeStack
{
    // STUB does nothing
    
    return [FCLispNIL NIL];
}

@end
