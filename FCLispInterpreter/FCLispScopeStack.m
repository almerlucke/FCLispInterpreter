//
//  FCLispScopeStack.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/1/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispScopeStack.h"
#import "FCLispEnvironment.h"
#import "FCLispObject.h"
#import "FCLispSymbol.h"

/**
 *  Private FCLispScopeStack interface
 */
@interface FCLispScopeStack ()
{
    NSMutableArray *_stack;
}
@end



@implementation FCLispScopeStack

#pragma mark - Initialize

- (void)initializeWithScope:(NSMutableDictionary *)scope
{
    if (scope) {
        _stack = [NSMutableArray arrayWithObject:scope];
    } else {
        _stack = [NSMutableArray array];
    }
    
}

- (id)initWithScope:(NSMutableDictionary *)scope
{
    if ((self = [super init])) {
        [self initializeWithScope:scope];
    }
    
    return self;
}

- (id)initWithScopeArray:(NSArray *)scopeArray
{
    if ((self = [super init])) {
        _stack = [NSMutableArray arrayWithArray:scopeArray];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithScopeArray:_stack];
}


#pragma mark - Convenience Methods

+ (FCLispScopeStack *)scopeStack
{
//    return [[self alloc] initWithScope:[NSMutableDictionary dictionary]];
    return [[self alloc] initWithScope:nil];
}

+ (FCLispScopeStack *)scopeStackWithScope:(NSMutableDictionary *)scope
{
    return [[self alloc] initWithScope:scope];
}


#pragma mark - Push And Pop

- (NSArray *)stack
{
    return _stack;
}

- (NSMutableDictionary *)topScope
{
    return ([_stack count] > 0)? [_stack objectAtIndex:0] : nil;
}

- (void)pushScopeStack:(FCLispScopeStack *)scopeStack
{
    NSMutableArray *otherStack = [NSMutableArray arrayWithArray:[scopeStack stack]];
    
    [otherStack addObjectsFromArray:_stack];
    
    _stack = otherStack;
}

- (void)popScopeStack:(FCLispScopeStack *)scopeStack
{
    // remove [[scopeStack stack] count] scopes from the top of the stack
    NSArray *otherStack = [scopeStack stack];
    NSInteger otherStackCount = [otherStack count];
    NSInteger leftOverCount = [_stack count] - otherStackCount;
    
    _stack = [[_stack subarrayWithRange:NSMakeRange(otherStackCount, leftOverCount)] mutableCopy];
}

- (void)pushScope:(NSMutableDictionary *)scope
{
    if (!scope) {
        scope = [NSMutableDictionary dictionary];
    }
    
    // add scope to the front of the stack
    [_stack insertObject:scope atIndex:0];
}

- (NSMutableDictionary *)popScope
{
    NSMutableDictionary *scope = nil;
    
    if ([_stack count] > 0) {
        // pop scope from the front of the stack
        scope = [_stack objectAtIndex:0];
        [_stack removeObjectAtIndex:0];
    }
    
    return scope;
}


#pragma mark - Set or Retrieve Binding

- (FCLispObject *)bindingForSymbol:(FCLispSymbol *)symbol
{
    FCLispObject *binding = nil;
    
    for (NSDictionary *scope in _stack) {
        binding = [scope objectForKey:symbol.name];
        if (binding) break;
    }
    
    return binding;
}

- (void)setBinding:(FCLispObject *)binding forSymbol:(FCLispSymbol *)symbol
{
    FCLispObject *previousBinding = nil;
    
    // first check if there is a previous binding
    for (NSMutableDictionary *scope in _stack) {
        previousBinding = [scope objectForKey:symbol.name];
        if (previousBinding) {
            // update current binding to new binding
            [scope setObject:binding forKey:symbol.name];
            break;
        }
    }
    
    if (!previousBinding) {
        // no previous binding, add binding
        [self addBinding:binding forSymbol:symbol];
    }
}

- (void)addBinding:(FCLispObject *)binding forSymbol:(FCLispSymbol *)symbol
{
    NSMutableDictionary *topScope = [self topScope];
    if (topScope) {
        [topScope setObject:binding forKey:symbol.name];
    }
}

@end
