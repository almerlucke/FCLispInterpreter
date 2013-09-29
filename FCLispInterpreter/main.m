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


int main(int argc, const char * argv[])
{
    @autoreleasepool {
        @try {
            FCLispParser *parser = [FCLispParser parserWithString:@"checkitoutmanbrodoitnow \"check it out now its the funk soul brother \\\"right about now do it! dot it!\""];
            FCLispParserToken *token = [parser getToken];
            
            while (token) {
                NSLog(@"token %@", token);
                token = [parser getToken];
            }
        }
        @catch (FCLispException *exception) {
            NSLog(@"out of memory");
        }
        @finally {
            
        }
    }
    return 0;
}

