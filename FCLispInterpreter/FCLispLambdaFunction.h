//
//  FCLispLambdaFunction.h
//  Lisp
//
//  Created by aFrogleap on 12/14/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCLispFunction.h"

@class FCLispScopeStack;

@interface FCLispLambdaFunction : FCLispFunction

// parameter list (symbols)
@property (nonatomic, strong) NSArray *params;

// array with body elements which are evaluated in sequence
@property (nonatomic, strong) NSArray *body;

// array with captured NSDictionary scopes
@property (nonatomic, copy) FCLispScopeStack *capuredScopeStack;

@end
