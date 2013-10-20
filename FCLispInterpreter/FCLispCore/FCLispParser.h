//
//  FCLispParser.h
//  Lisp
//
//  Created by aFrogleap on 12/15/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCLispParserToken.h"
#import "FCLispException.h"



/**
 *  Lisp parser, chop lisp syntax input into tokens
 */
@interface FCLispParser : NSObject

/**
 *  Initialize parser with string
 *
 *  @param string
 *
 *  @return FCLispParser object
 */
- (id)initWithString:(NSString *)string;

/**
 *  Initialize parser with data
 *
 *  @param data
 *
 *  @return FCLispParser object
 */
- (id)initWithData:(NSData *)data;

/**
 *  Initialize parser with file path
 *
 *  @param path
 *
 *  @return FCLispParser object
 */
- (id)initWithFileAtPath:(NSString *)path;

/**
 *  Class shortcut to create parser with string
 *
 *  @param string
 *
 *  @return FCLispParser object
 */
+ (FCLispParser *)parserWithString:(NSString *)string;

/**
 *  Class shortcut to create parser with data
 *
 *  @param data
 *
 *  @return FCLispParser object
 */
+ (FCLispParser *)parserWithData:(NSData *)data;

/**
 *  Class shortcut to create parser with file path
 *
 *  @param path
 *
 *  @return FCLispParser object
 */
+ (FCLispParser *)parserWithFileAtPath:(NSString *)path;

/**
 *  Get next token from parser (nil if no more tokens are available)
 *
 *  @return FCLispParserToken object
 */
- (FCLispParserToken *)getToken;

/**
 *  Get current line count
 *
 *  @return Line count
 */
- (NSInteger)lineCount;

/**
 *  Get current char count (is reset when LF, CR or CRLF is encountered)
 *
 *  @return Char count
 */
- (NSInteger)charCount;

@end