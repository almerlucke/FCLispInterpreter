//
//  FCLispSequence.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/20/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispObject.h"

/**
 *  FCLispSequence is an abstract class to provide the common interface for classes which are sequential in nature
 *  like cons, array, and string classes.
 */
@interface FCLispSequence : FCLispObject

/**
 *  All subclasses of sequence must implement length to get the number of objects they contain
 *
 *  @return NSUInteger length
 */
- (NSUInteger)length;

/**
 *  Get an object at index, all subclasses must implement this method
 *
 *  @return FCLispObject
 */
- (FCLispObject *)objectAtIndex:(NSUInteger)index;

/**
 *  Replace an object at index with another object, all subclasses must implement this method
 *
 *  @param index    
 *  @param anObject
 */
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(FCLispObject *)anObject;

@end
