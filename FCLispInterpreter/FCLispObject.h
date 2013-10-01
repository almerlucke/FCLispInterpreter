//
//  FCLispObject.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/1/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCLispEnvironment;

@interface FCLispObject : NSObject

/**
 *  Stub method, CAN be overwritten by subclasses to add buildin methods or constants to the global scope
 *  This method is called when classes register with the environment via registerClass
 *
 *  @param environment FCLispEnvironment object
 */
+ (void)addGlobalBindingsToEnvironment:(FCLispEnvironment *)environment;

@end
