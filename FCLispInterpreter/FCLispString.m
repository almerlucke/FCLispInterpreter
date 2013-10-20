//
//  FCLispString.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/2/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispString.h"
#import "FCUTF8String.h"
#import "FCLispCharacter.h"


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


#pragma mark - Encoding

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


#pragma mark - FCLispSequence

- (NSUInteger)length
{
    return _internalString.length;
}

- (FCLispObject *)objectAtIndex:(NSUInteger)index
{
    return [FCLispCharacter characterWithUTF8Char:[_internalString characterAtIndex:index]];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(FCLispObject *)anObject
{
    [_internalString replaceCharacterAtIndex:index withCharacter:((FCLispCharacter *)anObject).character];
}

@end
