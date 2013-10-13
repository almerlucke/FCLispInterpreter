//
//  FCLispString.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispString.h"



@implementation FCLispString

+ (FCLispString *)stringWithString:(NSString *)string
{
    FCLispString *lispString = [[FCLispString alloc] init];
    
    lispString.string = string;
    
    return lispString;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"\"%@\"", self.string];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.string forKey:@"string"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        self.string = [aDecoder decodeObjectForKey:@"string"];
    }
    
    return self;
}

@end
