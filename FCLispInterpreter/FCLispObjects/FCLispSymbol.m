//
//  FCLispSymbol.m
//  FCLispInterpreter
//
//  Created by Almer Lucke on 10/1/13.
//  Copyright (c) 2013 Farcoding. All rights reserved.
//

#import "FCLispSymbol.h"
#import "FCLispEnvironment.h"

@interface FCLispSymbol ()
{
    NSString *_name;
}
@end

@implementation FCLispSymbol


#pragma mark - Init

- (id)initWithName:(NSString *)name
{
    if (self = [super init]) {
        _name = [name uppercaseString];
        _type = FCLispSymbolTypeNormal;
        _value = nil;
    }
    
    return self;
}


#pragma mark - Gensym

+ (FCLispSymbol *)genSym:(NSString *)name
{
    return [FCLispEnvironment genSym:name];
}


#pragma mark - Properties

- (NSString *)name
{
    return _name;
}


#pragma mark - Description

- (NSString *)description
{
    return self.name;
}


#pragma mark - Encoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.name forKey:@"name"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString *name = [aDecoder decodeObjectForKey:@"name"];
    FCLispSymbol *sym = [FCLispSymbol genSym:name];
    
    return sym;
}

@end
