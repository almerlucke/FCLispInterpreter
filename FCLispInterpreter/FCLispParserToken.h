//
//  FCLispParserToken.h
//  Lisp
//
//  Created by aFrogleap on 12/18/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

typedef NS_ENUM(NSInteger, FCLispParserTokenType)
{
    FCLispParserTokenTypeUnknown = 0,
    FCLispParserTokenTypeOpenList = 1,
    FCLispParserTokenTypeCloseList = 2,
    FCLispParserTokenTypeQuote = 3,
    FCLispParserTokenTypeSymbol = 4,
    FCLispParserTokenTypeFloatNumber = 5,
    FCLispParserTokenTypeIntegerNumber = 6,
    FCLispParserTokenTypeString = 7,
    FCLispParserTokenTypeDot = 8
};

@interface FCLispParserToken : NSObject
@property (nonatomic) FCLispParserTokenType type;
@property (nonatomic, copy) NSString *value;

+ (FCLispParserToken *)tokenWithType:(FCLispParserTokenType)type;
+ (FCLispParserToken *)tokenWithType:(FCLispParserTokenType)type andValue:(NSString *)value;

@end
