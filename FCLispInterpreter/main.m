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
            FCLispParser *parser = [FCLispParser parserWithString:@"\"dhdhdh\n3444"];
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
    }
    return 0;
}

