//
//  main.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 9/29/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLisp.h"

int main(int argc, const char * argv[])
{
    // 4096 characters should be enough for our purposes
    char line[4096];
    
    @autoreleasepool {
        printf("Welcome to FCLisp, type (exit) to quit\n\n> ");
        while (YES) {
            @try {
                // get a line from stdin
                fgets(line, 4096, stdin);
                // convert c string to nsstring
                NSString *lispStatement = [NSString stringWithCString:line encoding:NSUTF8StringEncoding];
                // evaluate statement in try/catch block
                id obj = [FCLispInterpreter interpretString:lispStatement withScopeStack:[FCLispEnvironment mainScopeStack]];
                printf("%s\n> ", [[obj description] cStringUsingEncoding:NSUTF8StringEncoding]);
            }
            @catch (FCLispException *exception) {
                printf("%s: %s\n> ", [exception.name cStringUsingEncoding:NSUTF8StringEncoding],
                       [exception.reason cStringUsingEncoding:NSUTF8StringEncoding]);
            }
            @catch (NSException *exception) {
                printf("%s: %s\n> ", [exception.name cStringUsingEncoding:NSUTF8StringEncoding],
                       [exception.reason cStringUsingEncoding:NSUTF8StringEncoding]);
            }
        }
    }
    
    return 0;
}

