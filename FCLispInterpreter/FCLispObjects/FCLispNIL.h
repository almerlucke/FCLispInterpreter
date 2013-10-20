//
//  FCLispNIL.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispObject.h"

/**
 *  Lisp NIL object
 */
@interface FCLispNIL : FCLispObject

/**
 *  Singleton NIL instance
 *
 *  @return NIL
 */
+ (FCLispNIL *)NIL;

@end
