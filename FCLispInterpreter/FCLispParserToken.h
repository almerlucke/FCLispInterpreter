//
//  FCLispParserToken.h
//  Lisp
//
//  Created by aFrogleap on 12/18/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//


/**
 *  Lisp parser token types
 */
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



/**
 *  Lisp parser token
 */
@interface FCLispParserToken : NSObject

/**
 *  token type
 */
@property (nonatomic) FCLispParserTokenType type;

/**
 *  token value
 */
@property (nonatomic, copy) NSString *value;

/**
 *  Create a token with type
 *
 *  @param type FCLispParserTokenType
 *
 *  @return FCLispToken object
 */
+ (FCLispParserToken *)tokenWithType:(FCLispParserTokenType)type;

/**
 *  Create a token with type and value
 *
 *  @param type  FCLispParserTokenType
 *  @param value NSString value
 *
 *  @return FCLispToken object
 */
+ (FCLispParserToken *)tokenWithType:(FCLispParserTokenType)type andValue:(NSString *)value;

@end
