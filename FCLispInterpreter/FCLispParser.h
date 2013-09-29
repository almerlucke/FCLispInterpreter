//
//  FCLispParser.h
//  Lisp
//
//  Created by aFrogleap on 12/15/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCLispParserToken.h"

@interface FCLispParser : NSObject

#pragma mark - Init

// init parser with string
- (id)initWithString:(NSString *)string;
// init parser with data
- (id)initWithData:(NSData *)data;
// init parse with file path
- (id)initWithFileAtPath:(NSString *)path;

// init class shortcuts
+ (FCLispParser *)parserWithString:(NSString *)string;
+ (FCLispParser *)parserWithData:(NSData *)data;
+ (FCLispParser *)parserWithFileAtPath:(NSString *)path;

#pragma mark - Token
// get next token from parser (nil if no more tokens are available)
- (FCLispParserToken *)getToken;

@end