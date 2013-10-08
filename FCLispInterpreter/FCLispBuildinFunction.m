//
//  FCLispBuildinFunction.m
//  Lisp
//
//  Created by aFrogleap on 12/12/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "FCLispBuildinFunction.h"
#import "FCLispCons.h"
#import "FCLispSymbol.h"
#import "FCLispNIL.h"
#import "FCLispT.h"


@implementation FCLispBuildinFunction

#pragma mark - Init

- (id)initWithSelector:(SEL)selector
                target:(id)target
              evalArgs:(BOOL)evalArgs
              canBeSet:(BOOL)canBeSet
{
    if ((self = [super init])) {
        self.selector = selector;
        self.target = target;
        self.evalArgs = evalArgs;
        self.canBeSet = canBeSet;
    }
    
    return self;
}

+ (FCLispBuildinFunction *)functionWithSelector:(SEL)selector
                                         target:(id)target
{
    return [[self alloc] initWithSelector:selector target:target evalArgs:YES canBeSet:NO];
}

+ (FCLispBuildinFunction *)functionWithSelector:(SEL)selector
                                         target:(id)target
                                       evalArgs:(BOOL)evalArgs
{
    return [[self alloc] initWithSelector:selector target:target evalArgs:evalArgs canBeSet:NO];
}

+ (FCLispBuildinFunction *)functionWithSelector:(SEL)selector
                                         target:(id)target
                                       evalArgs:(BOOL)evalArgs
                                       canBeSet:(BOOL)canBeSet
{
    return [[self alloc] initWithSelector:selector target:target evalArgs:evalArgs canBeSet:canBeSet];
}



#pragma mark - Override eval

- (id)eval:(FCLispCons *)args scopeStack:(FCLispScopeStack *)scopeStack
{
    NSDictionary *callData = @{@"args" : args, @"scopeStack" : scopeStack};
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    // perform the given selector on target and pass args array as single argument to selector
    return [self.target performSelector:self.selector withObject:callData];
#pragma clang diagnostic pop
}

- (FCLispObject *)eval:(FCLispCons *)args value:(id)value scopeStack:(FCLispScopeStack *)scopeStack
{
    NSDictionary *callData = @{@"args" : args, @"value" : value, @"scopeStack" : scopeStack};
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    // perform the given selector on target and pass args array as single argument to selector
    return [self.target performSelector:self.selector withObject:callData];
#pragma clang diagnostic pop
}

@end
