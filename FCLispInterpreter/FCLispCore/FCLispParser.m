//
//  FCLispParser.m
//  Lisp
//
//  Created by aFrogleap on 12/15/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "FCLispParser.h"
#import "FCLispException.h"
#import "FCUTF8Char.h"
#import "FCUTF8String.h"
#import "FCUTF8CharacterStream.h"


#pragma mark - FCLispParserExceptionType

/**
 *  Internal parser exception types
 */
typedef NS_ENUM(NSInteger, FCLispParserExceptionType)
{
    FCLispParserExceptionTypeFailedToOpenStream,
    FCLispParserExceptionTypeUTF8Error,
    FCLispParserExceptionTypeEndOfStreamBeforeEndOfComment,
    FCLispParserExceptionTypeEndOfStreamBeforeEndOfString,
    FCLispParserExceptionTypeIllegalCharacter
};


@interface FCLispParserException : FCLispException

@end

@implementation FCLispParserException

+ (NSString *)exceptionName
{
    return @"FCLispParserException";
}

+ (NSString *)reasonForType:(NSInteger)type andUserInfo:(NSDictionary *)userInfo
{
    NSString *reason = @"";
    NSNumber *lineCount = [userInfo objectForKey:@"lineCount"];
    
    switch (type) {
        case FCLispParserExceptionTypeEndOfStreamBeforeEndOfComment:
            reason = [NSString stringWithFormat:@"Line %@, end of stream reached before end of comment", lineCount];
            break;
        case FCLispParserExceptionTypeEndOfStreamBeforeEndOfString:
            reason = [NSString stringWithFormat:@"Line %@, end of stream reached before end of string", lineCount];
            break;
        case FCLispParserExceptionTypeIllegalCharacter:
            reason = [NSString stringWithFormat:@"Line %@, illegal character %@", lineCount, [userInfo objectForKey:@"character"]];
            break;
        case FCLispParserExceptionTypeFailedToOpenStream:
            reason = @"Failed to open parser character stream";
            break;
        case FCLispParserExceptionTypeUTF8Error:
            reason = [userInfo objectForKey:@"UTF8Error"];
            break;
        default:
            break;
    }
    
    return reason;
}

@end



#pragma mark - FCLispParser


@interface FCLispParser ()
{
    FCUTF8CharacterStream *_characterStream;
    FCUTF8Char *_prevChar;
    FCUTF8Char *_curChar;
    FCUTF8Char *_nextChar;
    FCUTF8String *_tokenString;
    
    // stats
    NSInteger _lineCount;
    NSInteger _charCount;
}
@end

@implementation FCLispParser

#pragma mark - Init

- (id)init
{
    if ((self = [super init])) {
        _lineCount = 0;
        _charCount = 0;
        _tokenString = [[FCUTF8String alloc] init];
    }
    
    return self;
}

- (id)initWithString:(NSString *)string
{
    return [self initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (id)initWithData:(NSData *)data
{
    if ((self = [self init])) {
        _characterStream = [FCUTF8CharacterStream characterStreamWithData:data];
        if (!_characterStream) {
            @throw [FCLispParserException exceptionWithType:FCLispParserExceptionTypeFailedToOpenStream];
        }
        [self getChar];
        [self getChar];
    }
    
    return self;
}

- (id)initWithFileAtPath:(NSString *)path
{
    if ((self = [self init])) {
        _characterStream = [FCUTF8CharacterStream characterStreamWithFileAtPath:path];
        if (!_characterStream) {
            @throw [FCLispParserException exceptionWithType:FCLispParserExceptionTypeFailedToOpenStream];
        }
        [self getChar];
        [self getChar];
    }
    
    return self;
}

+ (FCLispParser *)parserWithString:(NSString *)string
{
    return [[self alloc] initWithString:string];
}

+ (FCLispParser *)parserWithData:(NSData *)data
{
    return [[self alloc] initWithData:data];
}

+ (FCLispParser *)parserWithFileAtPath:(NSString *)path
{
    return [[self alloc] initWithFileAtPath:path];
}


#pragma mark - Parse Utils

- (void)updateStats
{
    if (_curChar.unicodeCodePoint == 0x0A) {
        if (_prevChar.unicodeCodePoint != 0x0D) {
            _charCount = 0;
            _lineCount++;
        }
    } else if (_curChar.unicodeCodePoint == 0x0D) {
        _charCount = 0;
        _lineCount++;
    } else if (_curChar) {
        _charCount++;
    }
}

// get next character
- (FCUTF8Char *)getChar
{
    _prevChar = _curChar;
    _curChar = _nextChar;
    
    [self updateStats];
    
    NSError *error = nil;
    _nextChar = [_characterStream getCharacter:&error];
    
    if (error) {
        @throw [FCLispParserException exceptionWithType:FCLispParserExceptionTypeUTF8Error
                                               userInfo:@{@"UTF8Error": [error.userInfo objectForKey:NSLocalizedDescriptionKey]}];
    }
    
    return _curChar;
}

- (void)skipWhiteSpace
{
    while (isspace((int)_curChar.unicodeCodePoint)) {
        [self getChar];
    }
}

- (void)skipComment
{
    while (YES) {
        // check for end of comment char sequence */
        if (_curChar.unicodeCodePoint == '*' && _nextChar.unicodeCodePoint == '/') {
            // skip * char
            [self getChar];
            // skip / char
            [self getChar];
            break;
        } else if (_curChar) {
            [self getChar];
        } else {
            @throw [FCLispParserException exceptionWithType:FCLispParserExceptionTypeEndOfStreamBeforeEndOfComment
                                                   userInfo:[self lineInfo]];
        }
    }
}

#pragma mark - Info

- (NSInteger)lineCount
{
    return _lineCount + 1;
}

- (NSInteger)charCount
{
    return _charCount + 1;
}

- (NSDictionary *)lineInfo
{
    return @{@"lineCount": [NSNumber numberWithInteger:[self lineCount]],
             @"charCount": [NSNumber numberWithInteger:[self charCount]]};
}

- (NSDictionary *)userInfoWithDictionary:(NSDictionary *)dict
{
    NSMutableDictionary *mutDict = [NSMutableDictionary dictionaryWithDictionary:dict];
    [mutDict setObject:[NSNumber numberWithInteger:[self lineCount]] forKey:@"lineCount"];
    [mutDict setObject:[NSNumber numberWithInteger:[self charCount]] forKey:@"charCount"];
    
    return [NSDictionary dictionaryWithDictionary:mutDict];
}


#pragma mark - Tokens

- (FCLispParserToken *)getStringToken
{
    /*
     alert (beep)	\a
     backslash	\\
     backspace	\b
     carriage return	\r
     double quote	\"
     formfeed	\f
     horizontal tab	\t
     newline	\n
     null character	\0
     single quote	\'
     vertical tab	\v
     question mark	\?
     */
    while (YES) {
        if (_curChar.unicodeCodePoint == '\\') {
            // start of escape sequence, replace special escaped characters
            if (_nextChar.unicodeCodePoint == 'a') {
                [_tokenString appendCharacter:[FCUTF8Char charWithUnicodeCodePoint:'\a']];
            } else if (_nextChar.unicodeCodePoint == 'b') {
                [_tokenString appendCharacter:[FCUTF8Char charWithUnicodeCodePoint:'\b']];
            } else if (_nextChar.unicodeCodePoint == 'r') {
                [_tokenString appendCharacter:[FCUTF8Char charWithUnicodeCodePoint:'\r']];
            } else if (_nextChar.unicodeCodePoint == 'f') {
                [_tokenString appendCharacter:[FCUTF8Char charWithUnicodeCodePoint:'\f']];
            } else if (_nextChar.unicodeCodePoint == 't') {
                [_tokenString appendCharacter:[FCUTF8Char charWithUnicodeCodePoint:'\t']];
            } else if (_nextChar.unicodeCodePoint == 'n') {
                [_tokenString appendCharacter:[FCUTF8Char charWithUnicodeCodePoint:'\n']];
            } else if (_nextChar.unicodeCodePoint == '0') {
                [_tokenString appendCharacter:[FCUTF8Char charWithUnicodeCodePoint:'\0']];
            } else if (_nextChar.unicodeCodePoint == 'v') {
                [_tokenString appendCharacter:[FCUTF8Char charWithUnicodeCodePoint:'\v']];
            } else {
                // no special character, add next char to token
                [_tokenString appendCharacter:_nextChar];
            }
            // skip two chars (current and next)
            [self getChar];
            [self getChar];
        } else if (_curChar.unicodeCodePoint == '"') {
            // end of string
            [self getChar];
            break;
        } else if (!_curChar) {
            // signal an error if end of stream is reached before end of string
            @throw [FCLispParserException exceptionWithType:FCLispParserExceptionTypeEndOfStreamBeforeEndOfString
                                                   userInfo:[self lineInfo]];
        } else {
            // just add current char to token
            [_tokenString appendCharacter:_curChar];
            [self getChar];
        }
    }
    
    return [FCLispParserToken tokenWithType:FCLispParserTokenTypeString andValue:_tokenString.systemString];
}

- (FCLispParserToken *)getSymbolToken
{
    do {
        // add chars to token while we get symbol chars from stream
        [_tokenString appendCharacter:_curChar];
        [self getChar];
    } while ([[self class] isSymbolChar:_curChar.unicodeCodePoint]);
    
    NSString *value = _tokenString.systemString;
    
    if ([[self class] tokenIsInteger:value]) {
        // return integer token
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeIntegerNumber andValue:value];
    } else if ([[self class] tokenIsFloat:value]) {
        // return float token
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeFloatNumber andValue:value];
    } else if ([value isEqualToString:@"."]) {
        // return single dot token (cons a b)
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeDot];
    }
    
    // return pure symbol token
    return [FCLispParserToken tokenWithType:FCLispParserTokenTypeSymbol andValue:value];
}

- (FCLispParserToken *)getToken
{
    _tokenString = [[FCUTF8String alloc] init];
    
    // skip whitespace
    [self skipWhiteSpace];
    
    if (_curChar.unicodeCodePoint == '\'') {
        // quote symbol
        [self getChar];
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeQuote];
    } else if (_curChar.unicodeCodePoint == '(') {
        // start list symbol
        [self getChar];
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeOpenList];
    } else if (_curChar.unicodeCodePoint == ')') {
        // end list symbol
        [self getChar];
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeCloseList];
    } else if (_curChar.unicodeCodePoint == '[') {
        // start array
        [self getChar];
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeStartArray];
    } else if (_curChar.unicodeCodePoint == ']') {
        // end array
        [self getChar];
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeEndArray];
    } else if (_curChar.unicodeCodePoint == '{') {
        // start dictionary
        [self getChar];
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeStartDictionary];
    } else if (_curChar.unicodeCodePoint == '}') {
        // end dictionary
        [self getChar];
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeEndDictionary];
    } else if (_curChar.unicodeCodePoint == '"') {
        // skip ", get string symbol from rest chars
        [self getChar];
        return [self getStringToken];
    } else if (_curChar.unicodeCodePoint == '/') {
        // check if we are at start of comment -> /*
        if (_nextChar.unicodeCodePoint == '*') {
            // skip / and * chars
            [self getChar];
            [self getChar];
            // skip comment
            [self skipComment];
            // return next real token
            return [self getToken];
        } else {
            // try to return normal symbol token
            return [self getSymbolToken];
        }
    } else if ([[self class] isSymbolChar:_curChar.unicodeCodePoint]) {
        return [self getSymbolToken];
    } else if (_curChar) {
        @throw [FCLispParserException exceptionWithType:FCLispParserExceptionTypeIllegalCharacter
                                               userInfo:[self userInfoWithDictionary:@{@"character": _curChar}]];
    }
    
    return nil;
}

#pragma mark - Regular Expressions

+ (BOOL)isSymbolChar:(NSInteger)c
{
    // check if char c is part of symbol char collection
    NSString *stringToMatch = [NSString stringWithCharacters:(const unichar *)&c length:1];
    NSString *symbolMatchString = @"^[\\+\\-\\*\\/\\@\\$\\%\\^\\&\\_\\|\\=\\~\\.\\?\\!\\>\\<]|[a-zA-Z0-9]$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:symbolMatchString
                                                                           options:0
                                                                             error:nil];
    return ([regex numberOfMatchesInString:stringToMatch options:0 range:NSMakeRange(0, 1)] == 1);
}

+ (BOOL)tokenIsSymbol:(NSString *)token
{
    NSString *symbolMatchString = @"^([\\+\\-\\*\\/\\@\\$\\%\\^\\&\\_\\|\\=\\~\\.\\?\\!\\>\\<]|[a-zA-Z0-9])+$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:symbolMatchString
                                                                           options:0
                                                                             error:nil];
    return ([regex numberOfMatchesInString:token options:0 range:NSMakeRange(0, [token length])] == 1);
}

+ (BOOL)tokenIsFloat:(NSString *)token
{
    NSString *floatMatchString = @"^[-+]?(([0-9]+)|([0-9]+\\.)|(\\.[0-9]+)|([0-9]+\\.[0-9]+))([Ee][+-]?[0-9]+)?$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:floatMatchString
                                                                           options:0
                                                                             error:nil];
    return ([regex numberOfMatchesInString:token options:0 range:NSMakeRange(0, [token length])] == 1);
}

+ (BOOL)tokenIsInteger:(NSString *)token
{
    NSString *integerMatchString = @"^[-+]?[0-9]+$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:integerMatchString
                                                                           options:0
                                                                             error:nil];
    return ([regex numberOfMatchesInString:token options:0 range:NSMakeRange(0, [token length])] == 1);
}

@end
