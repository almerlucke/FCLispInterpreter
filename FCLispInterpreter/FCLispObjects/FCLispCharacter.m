//
//  FCLispCharacter.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/20/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispCharacter.h"
#import "FCUTF8Char.h"

@interface FCLispCharacter ()
{
    FCUTF8Char *_character;
}
@end

@implementation FCLispCharacter


#pragma mark - Init

- (id)initWithUTF8Char:(FCUTF8Char *)character
{
    if ((self = [super init])) {
        _character = character;
    }
    
    return self;
}

+ (FCLispCharacter *)characterWithUTF8Char:(FCUTF8Char *)character
{
    return [[self alloc] initWithUTF8Char:character];
}


#pragma mark - Encoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        _character = [FCUTF8Char charWithUnicodeCodePoint:[[aDecoder decodeObjectForKey:@"codePoint"] unsignedIntegerValue]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:_character.unicodeCodePoint] forKey:@"codePoint"];
}


#pragma mark - Copying

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithUTF8Char:_character];
}


#pragma mark - Other

- (FCUTF8Char *)character
{
    return _character;
}

- (NSString *)description
{
    // print characters as unicode code points
    return [NSString stringWithFormat:@"\\U%lx", (unsigned long)_character.unicodeCodePoint];
}

@end
