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

- (id)initWithName:(NSString *)name
{
    if (self = [super init]) {
        _name = [name uppercaseString];
    }
    
    return self;
}

+ (FCLispSymbol *)genSym:(NSString *)name
{
    return [FCLispEnvironment genSym:name];
}

- (NSString *)name
{
    return _name;
}

@end
