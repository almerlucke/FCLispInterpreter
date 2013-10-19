//
//  FCLisp.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/8/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//


// core
#import "FClispEnvironment.h"
#import "FCLispInterpreter.h"
#import "FCLispEvaluator.h"
#import "FCLispListBuilder.h"
#import "FCLispScopeStack.h"
#import "FCLispException.h"
#import "FCLispParser.h"
#import "FCLispParserToken.h"

// object classes
#import "FCLispObject.h"
#import "FCLispFunction.h"
#import "FCLispBuildinFunction.h"
#import "FCLispLambdaFunction.h"
#import "FCLispCons.h"
#import "FCLispSymbol.h"
#import "FCLispString.h"
#import "FCLispNumber.h"
#import "FCLispNIL.h"
#import "FCLispT.h"
#import "FCLispDictionary.h"
