//
//  GNEUnicodeUtilitiesTests.m
//  GNETextSearch
//
//  Created by Anthony Drendel on 1/2/16.
//  Copyright © 2016 Gone East LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GNEUnicodeUtilities.h"
#import "GNETextSearchPrivate.h"


// ------------------------------------------------------------------------------------------


@interface GNEUnicodeUtilitiesTests : XCTestCase

@end


// ------------------------------------------------------------------------------------------


@implementation GNEUnicodeUtilitiesTests


// ------------------------------------------------------------------------------------------
#pragma mark - Set Up / Tear Down
// ------------------------------------------------------------------------------------------
- (void)setUp
{
    [super setUp];
}


- (void)tearDown
{
    [super tearDown];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Tokenize
// ------------------------------------------------------------------------------------------
- (void)testTokenize_HelloAnthony_TwoTokens
{
    NSString *string = @"你好 Anthony";
    NSMutableArray *expectedTokens = [@[@"Hello", @"Anthony"] mutableCopy];
    GNEUnicodeTokenizeString(string.UTF8String, test_process);
}


void test_process(const char *string, GNERange range, uint32_t *token, size_t length)
{
    for (size_t i = 0; i < length; i++)
    {
        token[i] = CFSwapInt32HostToLittle(token[i]);
    }

    NSString *tokenStr = [[NSString alloc] initWithBytes:(void *)token
                                                  length:(sizeof(uint32_t) * (length))
                                                encoding:NSUTF32LittleEndianStringEncoding];
    NSLog(@"Token: %@", tokenStr);
}


// ------------------------------------------------------------------------------------------
#pragma mark - UTF-8 Code Points
// ------------------------------------------------------------------------------------------
- (void)testUTF8_Hello_Five
{
    NSString *string = @"Hello";
    uint32_t expected[] = {0x0048, 0x0065, 0x006C, 0x006C, 0x006F};
    [self p_assertCodePoints:expected length:5 inString:string];
}


- (void)testUTF8_NiHao_Two
{
    NSString *string = @"你好";
    uint32_t expected[] = {0x4F60, 0x597D};
    [self p_assertCodePoints:expected length:2 inString:string];
}


- (void)testUTF8_OkEmoji_One
{
    NSString *string = @"👌";
    uint32_t expected[] = {0x1F44C};
    [self p_assertCodePoints:expected length:1 inString:string];
}


- (void)testUTF8_AmericanFlagEmoji_Two
{
    NSString *string = @"🇺🇸";
    uint32_t expected[] = {0x1F1FA, 0x1F1F8};
    [self p_assertCodePoints:expected length:2 inString:string];
}


- (void)testUTF8_FamilyEmoji_Seven
{
    NSString *string = @"👨‍👩‍👧‍👦";
    uint32_t expected[] = {0x1F468, 0x200D, 0x1F469, 0x200D, 0x1F467, 0x200D, 0x1F466};
    [self p_assertCodePoints:expected length:7 inString:string];
}


// ------------------------------------------------------------------------------------------
#pragma mark - UTF-8 Character Count
// ------------------------------------------------------------------------------------------
- (void)testCharCount_Hello_OnePerCodePoint
{
    uint32_t codePoints[] = {0x0048, 0x0065, 0x006C, 0x006C, 0x006F};
    for (size_t i = 0; i < 5; i++)
    {
        XCTAssertEqual(1, GNEUnicodeNumberOfCharactersForCodePoint(codePoints[i]));
    }
}


- (void)testCharCount_NiHao_ThreePerCodePoint
{
    uint32_t codePoints[] = {0x4F60, 0x597D};
    for (size_t i = 0; i < 2; i++)
    {
        XCTAssertEqual(3, GNEUnicodeNumberOfCharactersForCodePoint(codePoints[i]));
    }
}


- (void)testCharCount_OkEmoji_Four
{
    uint32_t codePoints[] = {0x1F44C};
    XCTAssertEqual(4, GNEUnicodeNumberOfCharactersForCodePoint(codePoints[0]));
}


- (void)testCharCount_AmericanFlagEmoji_Five
{
    uint32_t codePoints[] = {0x1F1FA, 0x1F1F8};
    for (size_t i = 0; i < 2; i++)
    {
        XCTAssertEqual(4, GNEUnicodeNumberOfCharactersForCodePoint(codePoints[i]));
    }
}


- (void)testCharCount_FamilyEmoji_ThreeOrFourPerCodePoint
{
    uint32_t codePoints[] = {0x1F468, 0x200D, 0x1F469, 0x200D, 0x1F467, 0x200D, 0x1F466};
    XCTAssertEqual(4, GNEUnicodeNumberOfCharactersForCodePoint(codePoints[0]));
    XCTAssertEqual(3, GNEUnicodeNumberOfCharactersForCodePoint(codePoints[1]));
    XCTAssertEqual(4, GNEUnicodeNumberOfCharactersForCodePoint(codePoints[2]));
    XCTAssertEqual(3, GNEUnicodeNumberOfCharactersForCodePoint(codePoints[3]));
    XCTAssertEqual(4, GNEUnicodeNumberOfCharactersForCodePoint(codePoints[4]));
    XCTAssertEqual(3, GNEUnicodeNumberOfCharactersForCodePoint(codePoints[5]));
    XCTAssertEqual(4, GNEUnicodeNumberOfCharactersForCodePoint(codePoints[6]));
}


// ------------------------------------------------------------------------------------------
#pragma mark - UTF-16 Code Points
// ------------------------------------------------------------------------------------------
- (void)testUTF16_Hello_Five
{
    NSString *string = @"Hello";
    uint32_t expected[] = {0x0048, 0x0065, 0x006C, 0x006C, 0x006F};
    [self p_assertUTF16CodePoints:expected length:5 inString:string];
}


- (void)testUTF16_NiHao_Two
{
    NSString *string = @"你好";
    uint32_t expected[] = {0x4F60, 0x597D};
    [self p_assertUTF16CodePoints:expected length:2 inString:string];
}


- (void)testUTF16_OkEmoji_Two
{
    NSString *string = @"👌";
    uint32_t expected[] = {0xD83D, 0xDC4C};
    [self p_assertUTF16CodePoints:expected length:2 inString:string];
}


- (void)testUTF16_AmericanFlagEmoji_Four
{
    NSString *string = @"🇺🇸";
    uint32_t expected[] = {0xD83C, 0xDDFA, 0xD83C, 0xDDF8};
    [self p_assertUTF16CodePoints:expected length:4 inString:string];
}


- (void)testUTF16_FamilyEmoji_Eleven
{
    NSString *string = @"👨‍👩‍👧‍👦";
    uint32_t expected[] = {0xD83D, 0xDC68, 0x200D, 0xD83D, 0xDC69, 0x200D, 0xD83D, 0xDC67, 0x200D, 0xD83D, 0xDC66};
    [self p_assertUTF16CodePoints:expected length:11 inString:string];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Helpers
// ------------------------------------------------------------------------------------------
- (void)p_assertCodePoints:(uint32_t *)codePoints length:(size_t)length inString:(NSString *)string
{
    const char *cString = string.UTF8String;

    uint32_t *result = NULL;
    size_t resultLength = 0;

    XCTAssertEqual(SUCCESS, GNEUnicodeCopyCodePoints(cString, &result, &resultLength));
    XCTAssertEqual(length, resultLength);
    for (size_t i = 0; i < resultLength; i++)
    {
        XCTAssertEqual(codePoints[i], result[i]);
    }
}


- (void)p_assertUTF16CodePoints:(uint32_t *)codePoints length:(size_t)length inString:(NSString *)string
{
    const char *cString = string.UTF8String;

    uint32_t *result = NULL;
    size_t resultLength = 0;

    XCTAssertEqual(SUCCESS, GNEUnicodeCopyUTF16CodePoints(cString, &result, &resultLength));
    XCTAssertEqual(length, resultLength);
    for (size_t i = 0; i < resultLength; i++)
    {
        XCTAssertEqual(codePoints[i], result[i]);
    }
}


@end
