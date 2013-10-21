//
//  FCLispArray.h
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/21/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispSequence.h"

@interface FCLispArray : FCLispSequence

@property (nonatomic, readonly) NSMutableArray *array;

- (id)initWithArray:(NSArray *)array;

+ (FCLispArray *)arrayWithArray:(NSArray *)array;

@end
