//
//  FCLispDictionary.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/19/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispDictionary.h"
#import "FCLispException.h"
#import "FCLispEnvironment.h"
#import "FCLispBuildinFunction.h"
#import "FCLispNIL.h"
#import "FCLispT.h"
#import "FCLispSymbol.h"
#import "FCLispCons.h"
#import "FCLispString.h"
#import "FCLispEvaluator.h"
#import "FCLispScopeStack.h"


#pragma mark - FCLispDictionaryException

/**
 *  FCLispConsException types
 */
typedef NS_ENUM(NSInteger, FCLispDictionaryExceptionType)
{
    FCLispDictionaryExceptionTypeKeyIsNotAString,
    FCLispDictionaryExceptionTypeExpectedKeyValue,
    FCLispDictionaryExceptionTypeValueForKeyExpectedDictionary,
    FCLispDictionaryExceptionTypeValueForKeyExpectedKey
};

@interface FCLispDictionaryException : FCLispException

@end

@implementation FCLispDictionaryException

+ (NSString *)exceptionName
{
    return @"FCLispDictionaryException";
}

+ (NSString *)reasonForType:(NSInteger)type andUserInfo:(NSDictionary *)userInfo
{
    NSString *reason = @"";
    
    switch (type) {
        case FCLispDictionaryExceptionTypeKeyIsNotAString:
            reason = [NSString stringWithFormat:@"DICTIONARY key must be a string, %@ is not a string", [userInfo objectForKey:@"key"]];
            break;
        case FCLispDictionaryExceptionTypeExpectedKeyValue:
            reason = [NSString stringWithFormat:@"DICTIONARY expected a value for key %@", [userInfo objectForKey:@"key"]];
            break;
        case FCLispDictionaryExceptionTypeValueForKeyExpectedDictionary:
            reason = [NSString stringWithFormat:@"KEYVALUE(?) expected a dictionary as first argument, %@ is not a dictionary", [userInfo objectForKey:@"value"]];
            break;
        case FCLispDictionaryExceptionTypeValueForKeyExpectedKey:
            reason = [NSString stringWithFormat:@"KEYVALUE(?) expected a key as second argument, %@ is not a string", [userInfo objectForKey:@"value"]];
            break;
        default:
            break;
    }
    
    return reason;
}

@end



#pragma mark - FCLispDictionary

@interface FCLispDictionary ()
{
    NSMutableDictionary *_internalStorage;
}
@end


@implementation FCLispDictionary


#pragma mark - Init

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if ((self = [super init])) {
        _internalStorage = [dictionary mutableCopy];
    }
    
    return self;
}

+ (FCLispDictionary *)dictionaryWithDictionary:(NSDictionary *)dictionary
{
    return [[self alloc] initWithDictionary:dictionary];
}


#pragma mark - Encoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _internalStorage = [aDecoder decodeObjectForKey:@"dictionary"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_internalStorage forKey:@"dictionary"];
}


#pragma mark - Copying

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithDictionary:_internalStorage];
}


#pragma mark - Description

- (NSString *)description
{
    NSMutableString *str = [NSMutableString string];
    
    [str appendString:@"{"];
    
    BOOL first = YES;
    
    for (NSString *key in [_internalStorage allKeys]) {
        if (first) {
            [str appendFormat:@"\"%@\" %@", key, [_internalStorage objectForKey:key]];
            first = NO;
        } else {
            [str appendFormat:@" \"%@\" %@", key, [_internalStorage objectForKey:key]];
        }
    }
    
    [str appendString:@"}"];
    
    return [str copy];
}


#pragma mark - Properties

- (NSMutableDictionary *)dictionary
{
    return _internalStorage;
}


#pragma mark - Build in functions

+ (void)addGlobalBindingsToEnvironment:(FCLispEnvironment *)environment
{
    FCLispSymbol *global = nil;
    FCLispBuildinFunction *function = nil;
    
    // DICTIONARY
    global = [environment genSym:@"dictionary"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionDictionary:) target:self evalArgs:YES canBeSet:NO];
    global.value = function;
    function.documentation = @"Create a dictionary object from key-value pairs, keys must be strings,\n"
    "values can be any lisp object. (DICTIONARY &rest key value).\n"
    "example usage: (DICTIONARY \"foo\" 2 \"bar\" 3)";
    function.symbol = global;

    // KEYVALUE
    global = [environment genSym:@"keyvalue"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionObjectForKey:) target:self evalArgs:YES canBeSet:YES];
    global.value = function;
    function.documentation = @"Get or set a value for a key in the given dictionary,\n"
    "values can be any lisp object, keys must be strings. (KEYVALUE dictionary key).\n"
    "example usage: (KEYVALUE theDict \"theKey\") or (= (KEYVALUE theDict \"theKey\") 3)";
    function.symbol = global;
    
    // KEYVALUE?
    global = [environment genSym:@"keyvalue?"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionObjectForKeyExists:) target:self evalArgs:YES canBeSet:NO];
    global.value = function;
    function.documentation = @"Check if a key is set for the given dictionary (KEYVALUE? dictionary key).";
    function.symbol = global;
}


/**
 *  Create a dictionary object from key-value cons pairs ex: (dictionary '("a" 2) '("b" 4) '("c" "check it out")).
 *  Keys must be FCLispString objects. Values can be any lisp object.
 *
 *  @param callData
 *
 *  @return FCLispDictionary
 */
+ (FCLispObject *)buildinFunctionDictionary:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    while ([args isKindOfClass:[FCLispCons class]]) {
        FCLispString *key = (FCLispString *)args.car;
        
        if (![key isKindOfClass:[FCLispString class]]) {
            @throw [FCLispDictionaryException exceptionWithType:FCLispDictionaryExceptionTypeKeyIsNotAString
                                                       userInfo:@{@"key": key}];
        }
        
        args = (FCLispCons *)args.cdr;
        if (![args isKindOfClass:[FCLispCons class]]) {
            @throw [FCLispDictionaryException exceptionWithType:FCLispDictionaryExceptionTypeExpectedKeyValue
                                                       userInfo:@{@"key": key}];
        }
        
        [dictionary setObject:args.car forKey:key.string];
        
        args = (FCLispCons *)args.cdr;
    }
    
    return [self dictionaryWithDictionary:dictionary];
}

/**
 *  Get or set object for key (keyvalue dict "key") or (= (keyvalue dict "key") 3)
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
+ (FCLispObject *)buildinFunctionObjectForKey:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    FCLispScopeStack *scopeStack = [callData objectForKey:@"scopeStack"];
    FCLispObject *setfValue = [callData objectForKey:@"value"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    FCLispDictionary *lispDictionary = nil;
    FCLispString *keyString = nil;
    
    if (argc < 2) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"KEYVALUE",
                                                               @"numExpected" : @2}];
    }
    
    if (![args.car isKindOfClass:[FCLispDictionary class]]) {
        @throw [FCLispDictionaryException exceptionWithType:FCLispDictionaryExceptionTypeValueForKeyExpectedDictionary
                                                   userInfo:@{@"value" : args.car}];
    }
    
    lispDictionary = (FCLispDictionary *)args.car;
    
    args = (FCLispCons *)args.cdr;
    
    if (![args.car isKindOfClass:[FCLispString class]]) {
        @throw [FCLispDictionaryException exceptionWithType:FCLispDictionaryExceptionTypeValueForKeyExpectedKey
                                                   userInfo:@{@"value" : args.car}];
    }
    
    keyString = (FCLispString *)args.car;
    
    FCLispObject *returnValue = [FCLispNIL NIL];
    
    if (setfValue) {
        returnValue = [FCLispEvaluator eval:setfValue withScopeStack:scopeStack];
        [lispDictionary.dictionary setObject:returnValue forKey:keyString.string];
    } else {
        returnValue = [lispDictionary.dictionary objectForKey:keyString.string];
        if (!returnValue) returnValue = [FCLispNIL NIL];
    }
    
    return returnValue;
}

/**
 *  Check if a key is set on the given dictionary
 *
 *  @param callData
 *
 *  @return NIL or T
 */
+ (FCLispObject *)buildinFunctionObjectForKeyExists:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    FCLispDictionary *lispDictionary = nil;
    FCLispString *keyString = nil;
    
    if (argc < 2) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"KEYVALUE?",
                                                               @"numExpected" : @2}];
    }
    
    if (![args.car isKindOfClass:[FCLispDictionary class]]) {
        @throw [FCLispDictionaryException exceptionWithType:FCLispDictionaryExceptionTypeValueForKeyExpectedDictionary
                                                   userInfo:@{@"value" : args.car}];
    }
    
    lispDictionary = (FCLispDictionary *)args.car;
    
    args = (FCLispCons *)args.cdr;
    
    if (![args.car isKindOfClass:[FCLispString class]]) {
        @throw [FCLispDictionaryException exceptionWithType:FCLispDictionaryExceptionTypeValueForKeyExpectedKey
                                                   userInfo:@{@"value" : args.car}];
    }
    
    keyString = (FCLispString *)args.car;
    
    FCLispObject *returnValue = [lispDictionary.dictionary objectForKey:keyString.string];
    
    if (!returnValue) returnValue = [FCLispNIL NIL];
    else returnValue = [FCLispT T];
    
    return returnValue;
}

@end
