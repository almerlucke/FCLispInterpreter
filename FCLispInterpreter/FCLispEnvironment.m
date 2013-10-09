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
#import "NSArray+FCLisp.h"


#pragma mark - FClispEnvironmentException

@implementation FCLispEnvironmentException

+ (NSString *)exceptionName
{
    return @"FCLispEnvironmentException";
}

+ (NSString *)reasonForType:(NSInteger)type andUserInfo:(NSDictionary *)userInfo
{
    NSString *reason = @"";
    
    switch (type) {
        case FCLispEnvironmentExceptionTypeNumArguments: {
            NSString *functionName = [userInfo objectForKey:@"functionName"];
            NSNumber *numExpected = [userInfo objectForKey:@"numExpected"];
            reason = [NSString stringWithFormat:@"%@ expected at least %@ argument(s)", functionName, numExpected];
            break;
        }
        case FCLispEnvironmentExceptionTypeAssignmentToReservedSymbol:
            reason = [NSString stringWithFormat:@"Can't assign to reserved symbol %@", [userInfo objectForKey:@"symbolName"]];
            break;
        case FCLispEnvironmentExceptionTypeReturn:
            reason = @"Return can only be called inside a function body";
            break;
        case FCLispEnvironmentExceptionTypeBreak:
            reason = @"Break can only be called inside a loop body";
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


#pragma mark - Exceptions

+ (void)throwBreakException
{
    @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeBreak];
}

+ (void)throwReturnExceptionWithValue:(FCLispObject *)value
{
    @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeReturn
                                                userInfo:@{@"value" : value}];
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
    
    global = [self genSym:@"eval"];
    global.type = FCLispSymbolTypeBuildin;
    global.value = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionEval:) target:self evalArgs:YES];
    
    global = [self genSym:@"break"];
    global.type = FCLispSymbolTypeBuildin;
    global.value = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionBreak:) target:self evalArgs:NO];
    
    global = [self genSym:@"return"];
    global.type = FCLispSymbolTypeBuildin;
    global.value = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionReturn:) target:self evalArgs:YES];
    
    global = [self genSym:@"print"];
    global.type = FCLispSymbolTypeBuildin;
    global.value = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionPrint:) target:self evalArgs:YES];
    
    global = [self genSym:@"while"];
    global.type = FCLispSymbolTypeBuildin;
    global.value = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionWhile:) target:self evalArgs:NO];
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
                                                               @"numExpected" : @1}];
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
                                                               @"numExpected" : @2}];
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

- (FCLispObject *)buildinFunctionEval:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    FCLispScopeStack *scopeStack = [callData objectForKey:@"scopeStack"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 1) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"EVAL",
                                                               @"numExpected" : @1}];
    }
    
    return [FCLispEvaluator eval:args.car withScopeStack:scopeStack];
}

- (FCLispObject *)buildinFunctionBreak:(NSDictionary *)callData
{
    [[self class] throwBreakException];
    
    return [FCLispNIL NIL];
}

- (FCLispObject *)buildinFunctionReturn:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    FCLispObject *value = [FCLispNIL NIL];
    
    if (argc == 1) {
        value = args.car;
    }
    
    [[self class] throwReturnExceptionWithValue:value];
    
    return [FCLispNIL NIL];
}

- (FCLispObject *)buildinFunctionPrint:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 1) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"PRINT",
                                                               @"numExpected" : @1}];
    }
    
    FCLispObject *returnValue = [FCLispNIL NIL];
    
    // print arguments one by one
    while ([args isKindOfClass:[FCLispCons class]]) {
        printf("%s\n", [[args.car description] cStringUsingEncoding:NSUTF8StringEncoding]);
        returnValue = args.car;
        args = (FCLispCons *)args.cdr;
    }
    
    return returnValue;
}

- (FCLispObject *)buildinFunctionWhile:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    FCLispScopeStack *scopeStack = [callData objectForKey:@"scopeStack"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 1) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"WHILE",
                                                               @"numExpected" : @1}];
    }
    
    // loop condition is in first argument
    FCLispObject *loopCondition = args.car;
    
    // body is rest of arguments given
    NSArray *loopBody = [NSArray arrayWithCons:(FCLispCons *)args.cdr];
    
    FCLispObject *loopConditionResult = [FCLispEvaluator eval:loopCondition withScopeStack:scopeStack];
    FCLispObject *returnValue = [FCLispNIL NIL];
    
    // try/catch block to catch break exception to get out of loop prematurely
    // if exception is not a break exception, just pass it along
    @try {
        // loop until condition result is NIL or a break is thrown inside the loop body
        while ((FCLispNIL *)loopConditionResult != [FCLispNIL NIL]) {
            // evaluate body statements one by one
            for (id statement in loopBody) {
                returnValue = [FCLispEvaluator eval:statement withScopeStack:scopeStack];
            }
            // check loop condition again
            loopConditionResult = [FCLispEvaluator eval:loopCondition withScopeStack:scopeStack];
        }
    }
    @catch (FCLispException *exception) {
        if (!([exception.name isEqualToString:[FCLispEnvironmentException exceptionName]] &&
              exception.exceptionType == FCLispEnvironmentExceptionTypeBreak)) {
            @throw exception;
        }
    }
    
    return returnValue;
}

@end
