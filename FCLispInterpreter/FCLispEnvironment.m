//
//  FCLispEnvironment.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/1/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispEnvironment.h"
#import "FCLispSymbol.h"
#import "FCLispObject.h"
#import "FCLispScopeStack.h"
#import "FCLispCons.h"
#import "FCLispNIL.h"
#import "FCLispT.h"
#import "FCLispNumber.h"
#import "FCLispString.h"
#import "FCLispBuildinFunction.h"
#import "FCLispEvaluator.h"
#import "FCLispException.h"


/**
 *  Lisp environment error types
 */
typedef NS_ENUM(NSInteger, FCLispEnvironmentExceptionType)
{
    FCLispEnvironmentExceptionTypeNumArguments,
    FCLispEnvironmentExceptionTypeAssignmentToReservedSymbol
};


#pragma mark - FClispEnvironmentException

/**
 *  FClispEnvironmentException
 */
@interface FCLispEnvironmentException : FCLispException

@end

@implementation FCLispEnvironmentException

+ (NSString *)exceptionName
{
    return @"FCLispEnvironmentException";
}

+ (NSString *)reasonForType:(NSInteger)type andUserInfo:(NSDictionary *)userInfo
{
    NSString *reason = @"";
    
    switch (type) {
        case FCLispEnvironmentExceptionTypeNumArguments:
        {
            NSString *functionName = [userInfo objectForKey:@"functionName"];
            NSNumber *numExpected = [userInfo objectForKey:@"numExpected"];
            NSNumber *numGiven = [userInfo objectForKey:@"numGiven"];
            reason = [NSString stringWithFormat:@"%@ expected at least %@ arguments, %@ given", functionName, numExpected, numGiven];
            break;
        }
        case FCLispEnvironmentExceptionTypeAssignmentToReservedSymbol:
            reason = [NSString stringWithFormat:@"Can't assign to reserved symbol %@", [userInfo objectForKey:@"symbolName"]];
            break;
        default:
            break;
    }
    
    return reason;
}

@end



#pragma mark - FCLispEnvironment

/**
 *  Private interface
 */
@interface FCLispEnvironment ()
{
    /**
     *  Mutable dictionary containing all symbols in environment
     */
    NSMutableDictionary *_symbols;
    
    /**
     *  Creation of symbols MUST be thread safe, so we perform the creation of symbols 
     *  in serial on a dedicated queue
     */
    dispatch_queue_t _symbolCreationQueue;
    
    /**
     *  Default (main thread) scope stack
     */
    FCLispScopeStack *_scopeStack;
}
@end



@implementation FCLispEnvironment

#pragma mark - Singleton

+ (FCLispEnvironment *)defaultEnvironment
{
    static FCLispEnvironment *sDefaultEnvironment;
    static dispatch_once_t sDispatchOnce;
    
    dispatch_once(&sDispatchOnce, ^{
        sDefaultEnvironment = [[FCLispEnvironment alloc] init];
    });
    
    return sDefaultEnvironment;
}

- (id)init
{
    if ((self = [super init])) {
        // symbol dictionary
        _symbols = [NSMutableDictionary dictionary];
        
        // create serial symbol creation queue
        _symbolCreationQueue = dispatch_queue_create("kFCLispEnvironmentSymbolQueue", DISPATCH_QUEUE_SERIAL);
        
        // create main thread scope stack
        _scopeStack = [FCLispScopeStack scopeStack];
        
        // add buildin functions, reserved symbols, literals, and constants
        [self addGlobals];
         
        // register default classes
        [self registerClass:[FCLispSymbol class]];
        [self registerClass:[FCLispNumber class]];
        [self registerClass:[FCLispCons class]];
        [self registerClass:[FCLispString class]];
    }
    
    return self;
}


#pragma mark - GenSym

- (FCLispSymbol *)genSym:(NSString *)name
{
    // symbols should be uppercase
    NSString *uppercaseName = [name uppercaseString];
    
    // we want to assign to this variable from inside block, so use __block indicator
    __block FCLispSymbol *symbol = nil;
    
    // perform the creation of the symbol on a dedicated serial queue (making sure we don't create the symbol twice from
    // different threads)
    dispatch_sync(_symbolCreationQueue, ^{
        // first get symbol from cache
        symbol = [_symbols objectForKey:uppercaseName];
        
        if (!symbol) {
            // not cached so create a new symbol
            symbol = [[FCLispSymbol alloc] initWithName:uppercaseName];
            [_symbols setObject:symbol forKey:uppercaseName];
        }
    });
    
    return symbol;
}

+ (FCLispSymbol *)genSym:(NSString *)name
{
    return [[self defaultEnvironment] genSym:name];
}


#pragma mark - Register

- (void)registerClass:(Class)theClass
{
    if ([theClass isSubclassOfClass:[FCLispObject class]]) {
        [theClass addGlobalBindingsToEnvironment:self];
    }
}

+ (void)registerClass:(Class)theClass
{
    [[self defaultEnvironment] registerClass:theClass];
}


#pragma mark - Scope

- (FCLispScopeStack *)mainScopeStack
{
    return _scopeStack;
}

+ (FCLispScopeStack *)mainScopeStack
{
    return [[self defaultEnvironment] mainScopeStack];
}



#pragma mark - Buildin Functions

- (void)addGlobals
{
    FCLispSymbol *global = nil;
    
    global = [self genSym:@"nil"];
    global.type = FCLispSymbolTypeLiteral;
    global.value = [FCLispNIL NIL];
    
    global = [self genSym:@"t"];
    global.type = FCLispSymbolTypeLiteral;
    global.value = [FCLispT T];
    
    global = [self genSym:@"exit"];
    global.type = FCLispSymbolTypeBuildin;
    global.value = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionExit:) target:self];
    
    global = [self genSym:@"quote"];
    global.type = FCLispSymbolTypeBuildin;
    global.value = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionQuote:) target:self evalArgs:NO];
    
    global = [self genSym:@"="];
    global.type = FCLispSymbolTypeBuildin;
    global.value = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionSetf:) target:self evalArgs:NO];
}

- (FCLispObject *)buildinFunctionExit:(NSDictionary *)callData
{
    exit(0);
    
    return [FCLispNIL NIL];
}

- (FCLispObject *)buildinFunctionQuote:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 1) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"QUOTE",
                                                               @"numExpected" : @1,
                                                               @"numGiven" : [NSNumber numberWithInteger:argc]}];
    }
    
    return args.car;
}

- (FCLispObject *)buildinFunctionSetf:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    FCLispScopeStack *scopeStack = [callData objectForKey:@"scopeStack"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc != 2) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"=",
                                                               @"numExpected" : @2,
                                                               @"numGiven" : [NSNumber numberWithInteger:argc]}];
    }
    
    FCLispObject *setfPlace = args.car;
    FCLispObject *returnValue = nil;
    
    if ([setfPlace isKindOfClass:[FCLispSymbol class]]) {
        // handle setf of symbol here
        FCLispSymbol *sym = (FCLispSymbol *)setfPlace;
        
        if (sym.type != FCLispSymbolTypeNormal) {
            @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeAssignmentToReservedSymbol
                                                        userInfo:@{@"symbolName" : sym.name}];
        }
        
        // evaluate value to assign to symbol
        returnValue = [FCLispEvaluator eval:((FCLispCons *)args.cdr).car withScopeStack:scopeStack];
        
        // set binding
        [scopeStack setBinding:returnValue forSymbol:sym];
    } else {
        // try to eval special setf function form (for instance (= (car (cons 1 2)) 3))
        returnValue = [FCLispEvaluator eval:setfPlace value:((FCLispCons *)args.cdr).car withScopeStack:scopeStack];
    }
    
    return returnValue;
}

@end
