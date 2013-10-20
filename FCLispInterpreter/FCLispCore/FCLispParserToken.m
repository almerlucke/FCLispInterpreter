//
//  FCLispParserToken.m
//  Lisp
//
//  Created by aFrogleap on 12/18/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "FCLispParserToken.h"

@implementation FCLispParserToken

#pragma mark - Init

+ (FCLispParserToken *)tokenWithType:(FCLispParserTokenType)type
{
    FCLispParserToken *token = [[FCLispParserToken alloc] init];
    token.type = type;
    return token;
}

+ (FCLispParserToken *)tokenWithType:(FCLispParserTokenType)type andValue:(NSString *)value
{
    FCLispParserToken *token = [[FCLispParserToken alloc] init];
    token.type = type;
    token.value = value;
    return token;
}


#pragma mark - Description

// for debugging purposes
- (NSString *)description
{
    NSString *desc = @"";
    
    switch (self.type) {
        case FCLispParserTokenTypeUnknown:
            desc = @"Unknown";
            break;
        case FCLispParserTokenTypeOpenList:
            desc = @"Open list: (";
            break;
        case FCLispParserTokenTypeCloseList:
            desc = @"Close list: )";
            break;
        case FCLispParserTokenTypeQuote:
            desc = @"Quote: '";
            break;
        case  FCLispParserTokenTypeDot:
            desc = @"Dot: .";
            break;
        case FCLispParserTokenTypeSymbol:
            desc = [NSString stringWithFormat:@"Symbol: %@", self.value];
            break;
        case FCLispParserTokenTypeFloatNumber:
            desc = [NSString stringWithFormat:@"Float number: %@", self.value];
            break;
        case FCLispParserTokenTypeIntegerNumber:
            desc = [NSString stringWithFormat:@"Integer number: %@", self.value];
            break;
        case FCLispParserTokenTypeString:
            desc = [NSString stringWithFormat:@"String: \"%@\"", self.value];
            break;
        default:
            break;
    }
    
    return desc;
}

@end
