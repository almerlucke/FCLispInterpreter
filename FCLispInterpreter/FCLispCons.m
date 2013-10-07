//
//  FCList.m
//  Lisp
//
//  Created by aFrogleap on 11/26/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "FCLispCons.h"
#import "FCLispNIL.h"


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


#pragma mark - Utils

- (NSInteger)length
{
    NSInteger length = 1;
    FCLispObject *cdr = self.cdr;
    
    while ([cdr isKindOfClass:[self class]]) {
        ++length;
        cdr = ((FCLispCons *)cdr).cdr;
    }
    
    return length;
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


//#pragma mark - Buildin Functions
//
//+ (void)addBuildinFunctionsToEnvironment:(FCLispEnvironment *)environment
//{
//    // add CAR function
//    FCLispSymbol *sym = [environment addConstantSymbolWithName:@"car"];
//    sym.global = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionCar:)
//                                                      target:self
//                                                    evalArgs:YES
//                                                    canBeSet:YES]; // setf-able
//    
//    // add CDR function
//    sym = [environment addConstantSymbolWithName:@"cdr"];
//    sym.global = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionCdr:)
//                                                      target:self
//                                                    evalArgs:YES
//                                                    canBeSet:YES]; // setf-able
//    
//    // add CONS function
//    sym = [environment addConstantSymbolWithName:@"cons"];
//    sym.global = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionCons:)
//                                                      target:self
//                                                    evalArgs:YES];
//    
//    // add LIST function
//    sym = [environment addConstantSymbolWithName:@"list"];
//    sym.global = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionList:)
//                                                      target:self
//                                                    evalArgs:YES];
//    
//    // add APPEND function
//    sym = [environment addConstantSymbolWithName:@"append"];
//    sym.global = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionAppend:)
//                                                      target:self
//                                                    evalArgs:YES];
//}
//
//+ (id)buildinFunctionCons:(NSDictionary *)callData
//{
//    FCLispCons *args = [callData objectForKey:@"args"];
//    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
//    
//    if (argc != 2) {
//        NSString *reason = [NSString stringWithFormat:@"CONS expected 2 arguments, %ld given", argc];
//        NSException *exception = [NSException exceptionWithName:@"CONS exception"
//                                                         reason:reason
//                                                       userInfo:nil];
//        @throw exception;
//    }
//    
//    FCLispCons *cons = [self consWithCar:args.car andCdr:((FCLispCons *)args.cdr).car];
//    
//    return cons;
//}
//
//+ (id)buildinFunctionList:(NSDictionary *)callData
//{
//    return [callData objectForKey:@"args"];
//}
//
//+ (id)buildinFunctionCar:(NSDictionary *)callData
//{
//    FCLispCons *args = [callData objectForKey:@"args"];
//    FCLispEnvironment *environment = [callData objectForKey:@"env"];
//    id setfValue = [callData objectForKey:@"value"];
//    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
//    
//    if (argc != 1 || ![args.car isKindOfClass:[FCLispCons class]]) {
//        NSException *exception = [NSException exceptionWithName:@"CAR exception"
//                                                         reason:@"CAR expected a cons argument"
//                                                       userInfo:nil];
//        @throw exception;
//    }
//    
//    FCLispCons *cons = (FCLispCons *)args.car;
//    
//    // check if this call is made by setf (=)
//    if (setfValue) {
//        // set car to evaluated setf value
//        cons.car = [environment eval:setfValue];
//    }
//    
//    return cons.car;
//}
//
//+ (id)buildinFunctionCdr:(NSDictionary *)callData
//{
//    FCLispCons *args = [callData objectForKey:@"args"];
//    FCLispEnvironment *environment = [callData objectForKey:@"env"];
//    id setfValue = [callData objectForKey:@"value"];
//    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
//    
//    if (argc != 1 || ![args.car isKindOfClass:[FCLispCons class]]) {
//        NSException *exception = [NSException exceptionWithName:@"CDR exception"
//                                                         reason:@"CDR expected a cons argument"
//                                                       userInfo:nil];
//        @throw exception;
//    }
//    
//    FCLispCons *cons = (FCLispCons *)args.car;
//    
//    // check if this call is made by setf (=)
//    if (setfValue) {
//        // set cdr to evaluated setf value
//        cons.cdr = [environment eval:setfValue];
//    }
//    
//    return cons.cdr;
//}
//
//+ (id)buildinFunctionAppend:(NSDictionary *)callData
//{
//    FCLispCons *args = [callData objectForKey:@"args"];
//    FCLispListBuilder *listBuilder = [[FCLispListBuilder alloc] init];
//    
//    // loop through all list arguments and add all list elements in them to one list
//    while ([args isKindOfClass:[FCLispCons class]]) {
//        if ([args.car isKindOfClass:[FCLispCons class]]) {
//            FCLispCons *list = (FCLispCons *)args.car;
//            // add list arguments
//            while ([list isKindOfClass:[FCLispCons class]]) {
//                [listBuilder addCar:list.car];
//                list = (FCLispCons *)list.cdr;
//            }
//        } else if ((FCLispNIL *)args.car != [FCLispNIL NIL]) {
//            NSException *exception = [NSException exceptionWithName:@"APPEND exception"
//                                                             reason:@"APPEND argument is not a list"
//                                                           userInfo:nil];
//            @throw exception;
//        }
//        args = (FCLispCons *)args.cdr;
//    }
//    
//    return listBuilder.list;
//}

@end
