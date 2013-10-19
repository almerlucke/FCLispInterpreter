//
//  FCLispString.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispString.h"
#import "FCUTF8String.h"


@interface FCLispString ()
{
    FCUTF8String *_internalString;
}
@end

@implementation FCLispString

- (id)initWithString:(NSString *)string
{
    if ((self = [super init])) {
        _internalString = [FCUTF8String stringWithSystemString:string];
    }
    
    return self;
}

+ (FCLispString *)stringWithString:(NSString *)string
{
    return [[FCLispString alloc] initWithString:string];
}

- (NSString *)string
{
    return _internalString.systemString;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"\"%@\"", _internalString];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_internalString.systemString forKey:@"string"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _internalString = [FCUTF8String stringWithSystemString:[aDecoder decodeObjectForKey:@"string"]];
    }
    
    return self;
}

@end
