//
//  FCList.m
//  Lisp
//
//  Created by aFrogleap on 11/26/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "FCLispCons.h"
#import "FCLispNIL.h"
#import "FCLispSymbol.h"
#import "FCLispBuildinFunction.h"
#import "FCLispEnvironment.h"
#import "FCLispException.h"
#import "FCLispEvaluator.h"
#import "FCLispListBuilder.h"


#pragma mark - FCLispConsException

/**
 *  FCLispConsException types
 */
typedef NS_ENUM(NSInteger, FCLispConsExceptionType)
{
    FCLispConsExceptionTypeCarExpectedList,
    FCLispConsExceptionTypeCdrExpectedList,
    FCLispConsExceptionTypeAppendEncounteredNonList
};

@interface FCLispConsException : FCLispException

@end

@implementation FCLispConsException

+ (NSString *)exceptionName
{
    return @"FCLispConsException";
}

+ (NSString *)reasonForType:(NSInteger)type andUserInfo:(NSDictionary *)userInfo
{
    NSString *reason = @"";
    
    switch (type) {
        case FCLispConsExceptionTypeCarExpectedList:
            reason = [NSString stringWithFormat:@"CAR expected a list as argument, %@ is not a list", [userInfo objectForKey:@"value"]];
            break;
        case FCLispConsExceptionTypeCdrExpectedList:
            reason = [NSString stringWithFormat:@"CDR expected a list as argument, %@ is not a list", [userInfo objectForKey:@"value"]];
            break;
        case FCLispConsExceptionTypeAppendEncounteredNonList:
            reason = [NSString stringWithFormat:@"APPEND can only append lists, %@ is not a list", [userInfo objectForKey:@"value"]];
            break;
        default:
            break;
    }
    
    return reason;
}

@end


#pragma mark - FCLispCons

@implementation FCLispCons

#pragma mark - Init

- (id)init
{
    if ((self = [super init])) {
        self.car = [FCLispNIL NIL];
        self.cdr = [FCLispNIL NIL];
    }
    
    return self;
}

- (id)initWithCar:(id)car andCdr:(id)cdr
{
    if ((self = [super init])) {
        self.car = car;
        self.cdr = cdr;
    }
    
    return self;
}

+ (FCLispCons *)consWithCar:(id)car andCdr:(id)cdr
{
    return [[self alloc] initWithCar:car andCdr:cdr];
}


#pragma mark - FCLispSequence

- (NSUInteger)length
{
    NSUInteger length = 1;
    FCLispObject *cdr = self.cdr;
    
    while ([cdr isKindOfClass:[self class]]) {
        ++length;
        cdr = ((FCLispCons *)cdr).cdr;
    }
    
    return length;
}

- (FCLispObject *)objectAtIndex:(NSUInteger)index
{
    FCLispCons *cons = self;
    
    while (index > 0) {
        --index;
        cons = (FCLispCons *)cons.cdr;
    }
    
    return cons.car;
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(FCLispObject *)anObject
{
    FCLispCons *cons = self;
    
    while (index > 0) {
        --index;
        cons = (FCLispCons *)cons.cdr;
    }
    
    cons.car = anObject;
}


#pragma mark - Description

- (NSString *)description
{
    NSMutableString *descString = [NSMutableString stringWithString:@"("];
    FCLispObject *cons = self.cdr;
    
    [descString appendFormat:@"%@", self.car];
    
    while ([cons isKindOfClass:[FCLispCons class]]) {
        [descString appendFormat:@" %@", ((FCLispCons *)cons).car];
        cons = ((FCLispCons *)cons).cdr;
    }
    
    if (cons != [FCLispNIL NIL]) {
        // cdr is not NIL so print final cdr with dotted list format
        [descString appendFormat:@" . %@", cons];
    }
    
    [descString appendString:@")"];
    
    return [NSString stringWithString:descString];
}


#pragma mark - Encoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.car forKey:@"car"];
    [aCoder encodeObject:self.cdr forKey:@"cdr"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        self.car = [aDecoder decodeObjectForKey:@"car"];
        self.cdr = [aDecoder decodeObjectForKey:@"cdr"];
    }
    
    return self;
}


#pragma mark - Buildin Functions

+ (void)addGlobalBindingsToEnvironment:(FCLispEnvironment *)environment
{
    FCLispSymbol *global = nil;
    FCLispBuildinFunction *function = nil;
    
    // CAR
    global = [environment genSym:@"car"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionCar:) target:self evalArgs:YES canBeSet:YES];
    global.value = function;
    function.documentation = @"Get car of cons (CAR listObject) or set car of cons (= (CAR listObject) 2)";
    function.symbol = global;
    
    // CDR
    global = [environment genSym:@"cdr"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionCdr:) target:self evalArgs:YES canBeSet:YES];
    global.value = function;
    function.documentation = @"Get cdr of cons (CDR listObject) or set cdr of cons (= (CDR listObject) 2)";
    function.symbol = global;
    
    // CONS
    global = [environment genSym:@"cons"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionCons:) target:self];
    global.value = function;
    function.documentation = @"Create a cons with a car and optional cdr (CONS car &optional cdr)";
    function.symbol = global;
    
    // LIST
    global = [environment genSym:@"list"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionList:) target:self];
    global.value = function;
    function.documentation = @"Create a list (LIST &rest args)";
    function.symbol = global;
    
    // APPEND
    global = [environment genSym:@"append"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionAppend:) target:self];
    global.value = function;
    function.documentation = @"Append zero or more lists (APPEND &rest lists)";
    function.symbol = global;
}

/**
 *  Cons, create a new cons object from a car and optional cdr
 *
 *  @param callData
 *
 *  @return FCLispCons
 */
+ (FCLispObject *)buildinFunctionCons:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 1) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"CONS",
                                                               @"numExpected" : @1}];
    }
    
    FCLispObject *cdr = [FCLispNIL NIL];
    
    if (argc > 1) {
        cdr = ((FCLispCons *)args.cdr).car;
    }
    
    return [self consWithCar:args.car andCdr:cdr];
}

/**
 *  Create a list from args, because args is already a list, just return args
 *
 *  @param callData
 *
 *  @return FCLispCons
 */
+ (FCLispObject *)buildinFunctionList:(NSDictionary *)callData
{
    return [callData objectForKey:@"args"];
}

/**
 *  Get or set car of cons
 *
 *  @param callData
 *
 *  @return FClispObject
 */
+ (FCLispObject *)buildinFunctionCar:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    FCLispScopeStack *scopeStack = [callData objectForKey:@"scopeStack"];
    FCLispObject *setfValue = [callData objectForKey:@"value"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 1) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"CAR",
                                                               @"numExpected" : @1}];
    }
    
    if (![args.car isKindOfClass:[FCLispCons class]] && ![args.car isKindOfClass:[FCLispNIL class]]) {
        @throw [FCLispConsException exceptionWithType:FCLispConsExceptionTypeCarExpectedList
                                             userInfo:@{@"value": args.car}];
    }
    
    FCLispCons *cons = (FCLispCons *)args.car;
    FCLispObject *returnValue = [FCLispNIL NIL];
    
    if ([cons isKindOfClass:[FCLispCons class]]) {
        // check if this call is made by setf (=)
        if (setfValue) {
            // set car to evaluated setf value
            cons.car = [FCLispEvaluator eval:setfValue withScopeStack:scopeStack];
        }
        
        returnValue = cons.car;
    }
    
    return returnValue;
}

/**
 *  Get or set cdr of cons
 *
 *  @param callData
 *
 *  @return FClispObject
 */
+ (FCLispObject *)buildinFunctionCdr:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    FCLispScopeStack *scopeStack = [callData objectForKey:@"scopeStack"];
    FCLispObject *setfValue = [callData objectForKey:@"value"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 1) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"CDR",
                                                               @"numExpected" : @1}];
    }
    
    if (![args.car isKindOfClass:[FCLispCons class]] && ![args.car isKindOfClass:[FCLispNIL class]]) {
        @throw [FCLispConsException exceptionWithType:FCLispConsExceptionTypeCdrExpectedList
                                             userInfo:@{@"value": args.car}];
    }
    
    FCLispCons *cons = (FCLispCons *)args.car;
    FCLispObject *returnValue = [FCLispNIL NIL];
    
    if ([cons isKindOfClass:[FCLispCons class]]) {
        // check if this call is made by setf (=)
        if (setfValue) {
            // set car to evaluated setf value
            cons.cdr = [FCLispEvaluator eval:setfValue withScopeStack:scopeStack];
        }
        
        returnValue = cons.cdr;
    }
    
    return returnValue;
}

/**
 *  Append zero or more lists
 *
 *  @param callData
 *
 *  @return FCLispCons
 */
+ (FCLispObject *)buildinFunctionAppend:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    FCLispListBuilder *listBuilder = [[FCLispListBuilder alloc] init];
    
    // loop through all list arguments and add all list elements in them to one list
    while ([args isKindOfClass:[FCLispCons class]]) {
        if ([args.car isKindOfClass:[FCLispCons class]]) {
            FCLispCons *list = (FCLispCons *)args.car;
            // add list arguments
            while ([list isKindOfClass:[FCLispCons class]]) {
                [listBuilder addCar:list.car];
                list = (FCLispCons *)list.cdr;
            }
        } else if (![args.car isKindOfClass:[FCLispNIL class]]) {
            @throw [FCLispConsException exceptionWithType:FCLispConsExceptionTypeAppendEncounteredNonList
                                                 userInfo:@{@"value": args.car}];
        }
        
        args = (FCLispCons *)args.cdr;
    }
    
    return [listBuilder lispList];
}

@end
