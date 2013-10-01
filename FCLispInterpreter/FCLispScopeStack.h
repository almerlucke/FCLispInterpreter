//
//  FCLispScopeStack.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/1/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Push and pop scopes onto the stack
 *  Variable bindings are looked up through the scope stack
 *  Each scope is represented by a NSDictionary, where the key is the variable name and the value is the binding
 *  The first scope on the stack should always be the "global" scope
 *  Each thread MUST create a new scope stack and functions evaluated on that thread SHOULD use the corresponding stack
 */
@interface FCLispScopeStack : NSObject

@end