//
//  FCLispParser.m
//  Lisp
//
//  Created by aFrogleap on 12/15/12.
//  Copyright (c) 2012 Farcoding. All rights reserved.
//

#import "FCLispParser.h"
#import "FCLispException.h"


#define FCLISP_PARSER_BUFFER_LENGTH 4096
#define FCLISP_PARSER_INITIAL_MAX_TOKEN_LENGTH 4



@interface FCLispParser ()
{
    // character get
    NSInteger _prevChar;
    NSInteger _curChar;
    NSInteger _nextChar;
    NSInteger _bufferLength;
    NSInteger _bytesAvailable;
    NSInteger _curBytePos;
    uint8_t *_buffer;
    
    // tokens
    NSInteger _tokenMaxLength;
    NSInteger _tokenLength;
    uint8_t *_tokenBuffer;
    
    NSInputStream *_inputStream;
}
@end

@implementation FCLispParser

#pragma mark - Init/Dealloc

- (void)initialize
{
    _prevChar = EOF;
    _curChar = EOF;
    _nextChar = EOF;
    _bufferLength = FCLISP_PARSER_BUFFER_LENGTH;
    _curBytePos = 0;
    _buffer = (uint8_t *)malloc(sizeof(uint8_t) * _bufferLength);
    if (!_buffer) {
        @throw [FCLispException exceptionWithType:FCLispExceptionTypeOutOfMemory];
    }
    _bytesAvailable = 0;
    
    _tokenMaxLength = FCLISP_PARSER_INITIAL_MAX_TOKEN_LENGTH;
    _tokenLength = 0;
    _tokenBuffer = (uint8_t *)malloc(sizeof(uint8_t) * (_tokenMaxLength + 1));
    if (!_tokenBuffer) {
        @throw [FCLispException exceptionWithType:FCLispExceptionTypeOutOfMemory];
    }
    
    // call getchar twice for first time (fill cur and next char)
    [self getChar];
    [self getChar];
}

- (void)dealloc
{
    if (_inputStream) {
        [_inputStream close];
    }
    if (_buffer != NULL) {
        free(_buffer);
    }
    if (_tokenBuffer != NULL) {
        free(_tokenBuffer);
    }
}

- (id)init
{
    if ((self = [super init])) {
        _buffer = NULL;
        _tokenBuffer = NULL;
        _inputStream = nil;
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
        _inputStream = [NSInputStream inputStreamWithData:data];
        [_inputStream open];
        if (_inputStream.streamStatus != NSStreamStatusOpen) {
            return nil;
        }
        [self initialize];
    }
    
    return self;
}

- (id)initWithFileAtPath:(NSString *)path
{
    if ((self = [self init])) {
        _inputStream = [NSInputStream inputStreamWithFileAtPath:path];
        [_inputStream open];
        if (_inputStream.streamStatus != NSStreamStatusOpen) {
            return nil;
        }
        [self initialize];
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

// get next character
- (NSInteger)getChar
{
    _prevChar = _curChar;
    _curChar = _nextChar;
    if (_curBytePos >= _bytesAvailable) {
        _bytesAvailable = [_inputStream read:_buffer maxLength:_bufferLength];
        
        // if no bytes available return EOF
        if (_bytesAvailable < 1) {
            _nextChar = EOF;
        } else {
            _curBytePos = 0;
            // advance current byte pos
            _nextChar = _buffer[_curBytePos++];
        }
    } else {
        // advance current byte pos
        _nextChar = _buffer[_curBytePos++];
    }
    
    return _curChar;
}

// add a character to token
- (void)addTokenChar:(NSInteger)tokChar
{
    if (_tokenLength < _tokenMaxLength) {
        _tokenBuffer[_tokenLength++] = tokChar;
    } else {
        // tokenBuffer is filled to max, set token max length to twice the size before
        _tokenMaxLength <<= 1;
        
        // try to create new token buffer
        uint8_t *newTokenBuffer = (uint8_t *)malloc(sizeof(uint8_t) * (_tokenMaxLength + 1));
        if (!newTokenBuffer) {
            @throw [FCLispException exceptionWithType:FCLispExceptionTypeOutOfMemory];
        }
        
        // clear new token buffer and copy old token buffer into new
        memset(newTokenBuffer, 0, _tokenMaxLength + 1);
        memcpy(newTokenBuffer, _tokenBuffer, _tokenLength);
        
        // free old token buffer and set token buffer ptr to new token buffer
        free(_tokenBuffer);
        _tokenBuffer = newTokenBuffer;
        
        // try again
        [self addTokenChar:tokChar];
    }
}

- (void)skipWhiteSpace
{
    while (isspace((int)_curChar)) {
        [self getChar];
    }
}

- (void)skipComment
{
    while (YES) {
        // check for end of comment char sequence */
        if (_curChar == '*' && _nextChar == '/') {
            // skip * char
            [self getChar];
            // skip / char
            [self getChar];
            break;
        } else if (_curChar != EOF) {
            [self getChar];
        } else {
            NSString *reason = @"End of stream reached before closing comment";
            NSException *exception = [NSException exceptionWithName:@"PARSER exception"
                                                             reason:reason
                                                           userInfo:nil];
            @throw exception;
        }
    }
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
        if (_curChar == '\\') {
            // start of escape sequence, replace special escaped characters
            if (_nextChar == 'a') {
                [self addTokenChar:'\a'];
            } else if (_nextChar == 'b') {
                [self addTokenChar:'\b'];
            } else if (_nextChar == 'r') {
                [self addTokenChar:'\r'];
            } else if (_nextChar == 'f') {
                [self addTokenChar:'\f'];
            } else if (_nextChar == 't') {
                [self addTokenChar:'\t'];
            } else if (_nextChar == 'n') {
                [self addTokenChar:'\n'];
            } else if (_nextChar == '0') {
                [self addTokenChar:'\0'];
            } else if (_nextChar == 'v') {
                [self addTokenChar:'\v'];
            } else {
                // no special character, add next char to token
                [self addTokenChar:_nextChar];
            }
            // skip two chars (current and next)
            [self getChar];
            [self getChar];
        } else if (_curChar == '"') {
            // end of string
            [self getChar];
            break;
        } else if (_curChar == EOF) {
            // signal an error if end of stream is reached before end of string
            NSString *reason = @"End of stream reached before end of string";
            NSException *exception = [NSException exceptionWithName:@"PARSER error"
                                                             reason:reason
                                                           userInfo:nil];
            @throw  exception;
        } else {
            // just add current char to token
            [self addTokenChar:_curChar];
            [self getChar];
        }
    }
    
    NSString *value = [NSString stringWithUTF8String:(const char *)_tokenBuffer];
    
    return [FCLispParserToken tokenWithType:FCLispParserTokenTypeString andValue:value];
}

- (FCLispParserToken *)getSymbolToken
{
    do {
        // add chars to token while we get symbol chars from stream
        [self addTokenChar:_curChar];
        [self getChar];
    } while ([[self class] isSymbolChar:_curChar]);
    
    NSString *value = [NSString stringWithUTF8String:(const char *)_tokenBuffer];
    
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
    // reset token length
    _tokenLength = 0;
    
    // set all token buffer bytes to zero
    memset(_tokenBuffer, 0, _tokenMaxLength + 1);
    
    // skip whitespace
    [self skipWhiteSpace];
    
    if (_curChar == '\'') {
        // quote symbol
        [self getChar];
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeQuote];
    } else if (_curChar == '(') {
        // start list symbol
        [self getChar];
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeOpenList];
    } else if (_curChar == ')') {
        // end list symbol
        [self getChar];
        return [FCLispParserToken tokenWithType:FCLispParserTokenTypeCloseList];
    } else if (_curChar == '"') {
        // skip ", get string symbol from rest chars
        [self getChar];
        return [self getStringToken];
    } else if (_curChar == '/') {
        // check if we are at start of comment -> /*
        if (_nextChar == '*') {
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
    } else if ([[self class] isSymbolChar:_curChar]) {
        return [self getSymbolToken];
    } else if (_curChar != EOF) {
        NSString *reason = [NSString stringWithFormat:@"Illegal character %c encountered", (char)_curChar];
        NSException *exception = [NSException exceptionWithName:@"PARSER exception"
                                                         reason:reason
                                                       userInfo:nil];
        @throw exception;
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
