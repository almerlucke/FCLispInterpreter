//
//  main.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 9/29/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispParser.h"
#import "FCLispParserToken.h"
#import "FCLispException.h"
#import "FCLispEnvironment.h"
#import "FCLispSymbol.h"
#import "FCLispScopeStack.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        @try {
            FCLispParser *parser = [FCLispParser parserWithString:@"\"dhdhdh\" check"];
            FCLispParserToken *token = [parser getToken];
            
            while (token) {
                NSLog(@"token %@", token);
                token = [parser getToken];
            }
        }
        @catch (FCLispException *exception) {
            NSLog(@"%@: %@", exception.name, exception.reason);
        }
        @finally {
            
        }
        
        FCLispSymbol *firstSymbol = [FCLispSymbol genSym:@"first"];
        FCLispScopeStack *globalScopeStack = [FCLispEnvironment defaultScopeStack];
        [globalScopeStack addBinding:[FCLispSymbol genSym:@"check1"] forSymbol:firstSymbol];
        [globalScopeStack pushScope:nil];
        [globalScopeStack addBinding:[FCLispSymbol genSym:@"check2"] forSymbol:firstSymbol];
        NSLog(@"binding %@", [globalScopeStack bindingForSymbol:firstSymbol]);
        [globalScopeStack popScope];
        NSLog(@"binding %@", [globalScopeStack bindingForSymbol:firstSymbol]);
    }
    return 0;
}

