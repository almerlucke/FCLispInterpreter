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
#import "FCLispLambdaFunction.h"
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
        case FCLispEnvironmentExceptionTypeAssignmentToUnboundSymbol:
            reason = [NSString stringWithFormat:@"Can't assign to unbound symbol %@", [userInfo objectForKey:@"symbolName"]];
            break;
        case FCLispEnvironmentExceptionTypeReturn:
            reason = @"Return can only be called inside a function body";
            break;
        case FCLispEnvironmentExceptionTypeBreak:
            reason = @"Break can only be called inside a loop body";
            break;
        case FCLispEnvironmentExceptionTypeIllegalLambdaParamList:
            reason = @"LAMBDA expected a parameter list";
            break;
        case FCLispEnvironmentExceptionTypeLambdaParamListContainsNonSymbol:
            reason = [NSString stringWithFormat:@"LAMBDA parameter list contains non symbol value %@", [userInfo objectForKey:@"value"]];
            break;
        case FCLispEnvironmentExceptionTypeLambdaParamOverwriteReservedSymbol:
            reason = [NSString stringWithFormat:@"LAMBDA parameter shadows reserved symbol %@", [userInfo objectForKey:@"symbolName"]];
            break;
        case FCLispEnvironmentExceptionTypeDefineExpectedSymbol:
            reason = @"DEFINE expected a symbol as first parameter";
            break;
        case FCLispEnvironmentExceptionTypeDefineCanNotOverwriteSymbol:
            reason = [NSString stringWithFormat:@"DEFINE can not overwrite reserved or system defined symbol %@", [userInfo objectForKey:@"symbolName"]];
            break;
        case FCLispEnvironmentExceptionTypeLetParamOverwriteReservedSymbol:
            reason = [NSString stringWithFormat:@"LET parameter shadows reserved symbol %@", [userInfo objectForKey:@"symbolName"]];
            break;
        case FCLispEnvironmentExceptionTypeIllegalLetVariable:
            reason = [NSString stringWithFormat:@"Illegal LET variable %@", [userInfo objectForKey:@"value"]];
            break;
        case FCLispEnvironmentExceptionTypeLetExpectedVariableList:
            reason = [NSString stringWithFormat:@"LET expected a variable list, %@ is not a list", [userInfo objectForKey:@"value"]];
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
    
    // &rest is used to pass any number of parameters to a lambda function
    global = [self genSym:@"&rest"];
    global.type = FCLispSymbolTypeReserved;
    
    
    FCLispBuildinFunction *function = nil;
    
    // EXIT
    global = [self genSym:@"exit"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionExit:) target:self];
    global.value = function;
    function.documentation = @"Exit from the program (EXIT)";
    
    // QUOTE
    global = [self genSym:@"quote"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionQuote:) target:self evalArgs:NO];
    global.value = function;
    function.documentation = @"Delay evaluation of quoted object (QUOTE obj) or 'obj";
    
    // SETF (=)
    global = [self genSym:@"="];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionSetf:) target:self evalArgs:NO];
    global.value = function;
    function.documentation = @"Assign a value to a setable place (= place value)";
    
    // EVAL
    global = [self genSym:@"eval"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionEval:) target:self evalArgs:YES];
    global.value = function;
    function.documentation = @"Evaluate an object (EVAL obj)";
    
    // BREAK
    global = [self genSym:@"break"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionBreak:) target:self evalArgs:NO];
    global.value = function;
    function.documentation = @"Forced break from a loop body (BREAK)";
    
    // RETURN
    global = [self genSym:@"return"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionReturn:) target:self evalArgs:YES];
    global.value = function;
    function.documentation = @"Forced return from a lambda body (RETURN &optional obj)";
    
    // PRINT
    global = [self genSym:@"print"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionPrint:) target:self evalArgs:YES];
    global.value = function;
    function.documentation = @"Quick print object(s) to console (PRINT obj &rest moreObjects)";
    
    // WHILE
    global = [self genSym:@"while"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionWhile:) target:self evalArgs:NO];
    global.value = function;
    function.documentation = @"Loop through body until loop condition is NIL (WHILE loopCondition &rest body)";
    
    // DEFINE
    global = [self genSym:@"define"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionDefine:) target:self evalArgs:NO];
    global.value = function;
    function.documentation = @"Define a global variable (DEFINE symbol &optional value)";
    
    // LAMBDA
    global = [self genSym:@"lambda"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionLambda:) target:self evalArgs:NO];
    global.value = function;
    function.documentation = @"Create a lambda function (LAMBDA argList &rest body)";
    
    // LET
    global = [self genSym:@"let"];
    global.type = FCLispSymbolTypeBuildin;
    function = [FCLispBuildinFunction functionWithSelector:@selector(buildinFunctionLet:) target:self evalArgs:NO];
    global.value = function;
    function.documentation = @"Create a local scope and execute the body (LET varList &rest body)";
}


/**
 *  Build in function EXIT
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
- (FCLispObject *)buildinFunctionExit:(NSDictionary *)callData
{
    exit(0);
    
    return [FCLispNIL NIL];
}

/**
 *  Build in function QUOTE (delay execution of lisp object)
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
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

/**
 *  Build in function = (equivalent of SETF), assign value to setf-able place
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
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
    FCLispObject *returnValue = [FCLispNIL NIL];
    
    if ([setfPlace isKindOfClass:[FCLispSymbol class]]) {
        // handle setf of symbol here
        FCLispSymbol *sym = (FCLispSymbol *)setfPlace;
        
        if (sym.type == FCLispSymbolTypeReserved || sym.type == FCLispSymbolTypeLiteral) {
            @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeAssignmentToReservedSymbol
                                                        userInfo:@{@"symbolName" : sym.name}];
        }
        
        // evaluate value to assign to symbol
        returnValue = [FCLispEvaluator eval:((FCLispCons *)args.cdr).car withScopeStack:scopeStack];
        
        // get scoped binding
        FCLispObject *binding = [scopeStack bindingForSymbol:sym];
        
        if (!binding) {
            // if symbol is not bound in scope, we can only bind to defined variable
            if (sym.type == FCLispSymbolTypeDefined) {
                sym.value = returnValue;
            } else {
                @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeAssignmentToUnboundSymbol
                                                            userInfo:@{@"symbolName" : sym.name}];
            }
        } else {
            // set binding
            [scopeStack setBinding:returnValue forSymbol:sym];
        }
    } else {
        // try to eval special setf function form (for instance (= (car (cons 1 2)) 3))
        returnValue = [FCLispEvaluator eval:setfPlace value:((FCLispCons *)args.cdr).car withScopeStack:scopeStack];
    }
    
    return returnValue;
}

/**
 *  Build in function EVAL, evaluate a lisp object to it's value
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
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

/**
 *  Build in function BREAK, break from looping constructs
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
- (FCLispObject *)buildinFunctionBreak:(NSDictionary *)callData
{
    [[self class] throwBreakException];
    
    return [FCLispNIL NIL];
}

/**
 *  Build in function RETURN, forced return from a lambda body
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
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

/**
 *  Build in function PRINT, quick printing of one or more lisp objects
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
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

/**
 *  Build in function WHILE, while loop, loop until NIL is encountered
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
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

/**
 *  Define a global bound variable
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
- (FCLispObject *)buildinFunctionDefine:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    FCLispScopeStack *scopeStack = [callData objectForKey:@"scopeStack"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 1) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"DEFINE",
                                                               @"numExpected" : @1}];
    }
    
    FCLispSymbol *sym = (FCLispSymbol *)args.car;
    
    if (![sym isKindOfClass:[FCLispSymbol class]]) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeDefineExpectedSymbol];
    } else {
        if (sym.type == FCLispSymbolTypeLiteral ||
            sym.type == FCLispSymbolTypeBuildin ||
            sym.type == FCLispSymbolTypeReserved) {
            @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeDefineCanNotOverwriteSymbol
                                                        userInfo:@{@"symbolName": sym.name}];
        }
    }
    
    sym.type = FCLispSymbolTypeDefined;
    
    FCLispObject *returnValue = [FCLispNIL NIL];
    
    args = (FCLispCons *)args.cdr;
    if ([args isKindOfClass:[FCLispCons class]]) {
        returnValue = [FCLispEvaluator eval:args.car withScopeStack:scopeStack];
    }
    
    sym.value = returnValue;
    
    return returnValue;
}

/**
 *  Build in function LAMBDA, create a lambda function.
 *  A lambda function copies the current scopeStack, so all captured bindings are available when the
 *  function is called.
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
- (FCLispObject *)buildinFunctionLambda:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    FCLispScopeStack *scopeStack = [callData objectForKey:@"scopeStack"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 1) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"LAMBDA",
                                                               @"numExpected" : @1}];
    }
    
    // check if we have a valid parameter list (a list containing only symbols)
    FCLispCons *params = (FCLispCons *)args.car;
    if (![params isKindOfClass:[FCLispCons class]] &&
        ![params isKindOfClass:[FCLispNIL class]]) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeIllegalLambdaParamList];
    }
    
    // check if all parameters are symbols
    while ([params isKindOfClass:[FCLispCons class]]) {
        if (![params.car isKindOfClass:[FCLispSymbol class]]) {
            @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeLambdaParamListContainsNonSymbol
                                                        userInfo:@{@"value" : params.car}];
        }
        
        FCLispSymbol *sym = (FCLispSymbol *)params.car;
        
        if (sym.type == FCLispSymbolTypeReserved || sym.type == FCLispSymbolTypeLiteral) {
            @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeLambdaParamOverwriteReservedSymbol
                                                        userInfo:@{@"symbolName": sym.name}];
        }
        
        params = (FCLispCons *)params.cdr;
    }
    
    FCLispLambdaFunction *lambdaFunction = [[FCLispLambdaFunction alloc] init];
    // assign parameter list
    lambdaFunction.params = [NSArray arrayWithCons:(FCLispCons *)args.car];
    // lambda body is the rest of the args list
    lambdaFunction.body = [NSArray arrayWithCons:(FCLispCons *)args.cdr];
    // capture a copy of the current scopeStack
    lambdaFunction.capuredScopeStack = scopeStack;
    
    return lambdaFunction;
}


/**
 *  Create a local scope and execute a LET scope block. LET defines a new scope, adds local variables and evaluates its body.
 *
 *  @param callData
 *
 *  @return FCLispObject
 */
- (FCLispObject *)buildinFunctionLet:(NSDictionary *)callData
{
    FCLispCons *args = [callData objectForKey:@"args"];
    FCLispScopeStack *scopeStack = [callData objectForKey:@"scopeStack"];
    NSInteger argc = ([args isKindOfClass:[FCLispCons class]])? [args length] : 0;
    
    if (argc < 1) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeNumArguments
                                                    userInfo:@{@"functionName" : @"LET",
                                                               @"numExpected" : @1}];
    }
    
    FCLispCons *variableList = (FCLispCons *)args.car;
    if (![variableList isKindOfClass:[FCLispCons class]] &&
        ![variableList isKindOfClass:[FCLispNIL class]]) {
        @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeLetExpectedVariableList
                                                    userInfo:@{@"value" : variableList}];
    }
    
    // define cleanup block
    void (^cleanupBlock)() = ^{
        [scopeStack popScope];
    };
    
    // push a new scope on stack
    [scopeStack pushScope:nil];
    
    @try {
        // try to define local variables one by one, if an error occurs cleanup
        while ([variableList isKindOfClass:[FCLispCons class]]) {
            // we dont know if var desc is symbol or cons yet
            FCLispObject *variableDescription = variableList.car;
            FCLispSymbol *variable = nil;
            FCLispObject *variableValue = [FCLispNIL NIL];
            
            if ([variableDescription isKindOfClass:[FCLispSymbol class]]) {
                // variable is symbol only (assign NIL)
                variable = (FCLispSymbol *)variableDescription;
                // check for reserved symbols
                if (variable.type == FCLispSymbolTypeReserved || variable.type == FCLispSymbolTypeLiteral) {
                    @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeLetParamOverwriteReservedSymbol
                                                                userInfo:@{@"symbolName" : variable.name}];
                }
            } else if ([variableDescription isKindOfClass:[FCLispCons class]]) {
                // check if we have a valid symbol and value variable assignment
                NSInteger varDescLen = [((FCLispCons *)variableDescription) length];
                variable = (FCLispSymbol *)((FCLispCons *)variableDescription).car;
                if (![variable isKindOfClass:[FCLispSymbol class]] || varDescLen != 2) {
                    @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeIllegalLetVariable
                                                                userInfo:@{@"value" : variableDescription}];
                }
                // check for reserved symbols
                if (variable.type == FCLispSymbolTypeReserved || variable.type == FCLispSymbolTypeLiteral) {
                    @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeLetParamOverwriteReservedSymbol
                                                                userInfo:@{@"symbolName" : variable.name}];
                }
                // value needs to be evaluated first
                variableValue = [FCLispEvaluator eval:((FCLispCons *)((FCLispCons *)variableDescription).cdr).car
                                       withScopeStack:scopeStack];
            } else {
                @throw [FCLispEnvironmentException exceptionWithType:FCLispEnvironmentExceptionTypeIllegalLetVariable
                                                            userInfo:@{@"value" : variableDescription}];
            }
            
            // add binding to scope
            [scopeStack addBinding:variableValue forSymbol:variable];
         
            // goto next variable
            variableList = (FCLispCons *)variableList.cdr;
        }
    }
    @catch (NSException *exception) {
        cleanupBlock();
        @throw exception;
    }
    
    // loop through rest of LET body and evaluate statements
    args = (FCLispCons *)args.cdr;
    FCLispObject *returnValue = [FCLispNIL NIL];
    
    @try {
        while ([args isKindOfClass:[FCLispCons class]]) {
            returnValue = [FCLispEvaluator eval:args.car withScopeStack:scopeStack];
            args = (FCLispCons *)args.cdr;
        }
    }
    @catch (NSException *exception) {
        cleanupBlock();
        @throw exception;
    }
    
    cleanupBlock();
    
    return returnValue;
}


@end
