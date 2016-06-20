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
    NSString *string = @"Hello Anthony";
    NSArray *expected = @[@"Hello", @"Anthony"];

    NSMutableArray *processedTokens = [NSMutableArray array];
    GNEUnicodeTokenizeString(string.UTF8String, p_processTestToken, (__bridge void *)processedTokens);
    XCTAssertEqualObjects(expected, processedTokens);
}


- (void)testTokenize_SpaceHelloAnthonySpace_TwoTokens
{
    NSString *string = @" Hello Anthony ";
    NSArray *expected = @[@"Hello", @"Anthony"];

    NSMutableArray *processedTokens = [NSMutableArray array];
    GNEUnicodeTokenizeString(string.UTF8String, p_processTestToken, (__bridge void *)processedTokens);
    XCTAssertEqualObjects(expected, processedTokens);
}


- (void)testTokenize_NiHaoAnthony_TwoTokens
{
    NSString *string = @"你好 Anthony";
    NSArray *expected = @[@"你好", @"Anthony"];

    NSMutableArray *processedTokens = [NSMutableArray array];
    GNEUnicodeTokenizeString(string.UTF8String, p_processTestToken, (__bridge void *)processedTokens);
    XCTAssertEqualObjects(expected, processedTokens);
}

- (void)testTokenizeTwoLongTokens
{
    NSString *string = @"AnthonyIsAwesomeAndThisIsOneLongToken ThisIsOneLongButShorterToken";
    NSArray *expected = @[@"AnthonyIsAwesomeAndThisIsOneLongToken", @"ThisIsOneLongButShorterToken"];

    NSMutableArray *processedTokens = [NSMutableArray array];
    GNEUnicodeTokenizeString(string.UTF8String, p_processTestToken, (__bridge void *)processedTokens);
    XCTAssertEqualObjects(expected, processedTokens);
}

- (void)testTokenize_WoDeMingziShiAnDongNiWithFullWidthSpaces_FiveTokens
{
    NSString *string = @" 我  的  名字   是     安东尼     ";
    NSArray *expected = @[@"我", @"的", @"名字", @"是", @"安东尼"];

    NSMutableArray *processedTokens = [NSMutableArray array];
    GNEUnicodeTokenizeString(string.UTF8String, p_processTestToken, (__bridge void *)processedTokens);
    XCTAssertEqualObjects(expected, processedTokens);
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


- (void)testUTF8_LongChineseString_1799
{
    NSString *string = [self p_longChineseString];
    uint32_t *expected = [self p_newLongChineseUnicodeCodePoints];
    [self p_assertCodePoints:expected length:1799 inString:string];
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

    XCTAssertEqual(success, GNEUnicodeCopyCodePoints(cString, &result, &resultLength));
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

    XCTAssertEqual(success, GNEUnicodeCopyUTF16CodePoints(cString, &result, &resultLength));
    XCTAssertEqual(length, resultLength);
    for (size_t i = 0; i < resultLength; i++)
    {
        XCTAssertEqual(codePoints[i], result[i]);
    }
}


void p_processTestToken(const char *string, GNERange range, uint32_t *token, size_t length, void *context)
{
    NSMutableArray *processedTokens = (__bridge NSMutableArray *)context;
    assert([processedTokens isKindOfClass:[NSMutableArray class]]);

    for (size_t i = 0; i < length; i++)
    {
        token[i] = CFSwapInt32HostToLittle(token[i]);
    }

    NSString *tokenStr = [[NSString alloc] initWithBytes:(void *)token
                                                  length:(sizeof(uint32_t) * (length))
                                                encoding:NSUTF32LittleEndianStringEncoding];
    if (tokenStr)
    {
        [processedTokens addObject:tokenStr];
    }
}


- (NSString *)p_longChineseString
{
    return @"阶级斗争，一些阶级胜利了，一些阶级消灭了。这就是历史，这就是几千年来的文明史。拿这个观点解释历史的就叫做历史的唯物主义，站在这个观点的反面的是历史的唯心主义。《丢掉幻想，准备斗争》（一九四九年八月十四日），《毛泽东选集》第四卷第一四九一页。地主阶级对于农民的残酷的经济剥削和政治压迫，迫使农民多次地举行起义，以反抗地主阶级的统治。……在中国封建社会里，只有这些农民的阶级斗争、农民的起义和农民的战争，才是历史发展的真正动力。《中国革命和中国共产党》（一九三九年十二月）。人民靠我们去组织，中国的反动分子，靠我们组织起人民去把他打倒。凡是反动的东西，你不打，他就不倒。这也和扫地一样，扫帚不到，灰尘照例不会自己跑掉。《抗日战争胜利后的时局和我们的方针》（一九四五年八月十三日）《毛泽东选集》第四卷一一三一页。革命不是请客吃饭，不是做文章，不是绘画绣花，不能那样雅致，那样从容不迫，文质彬彬，那样温良恭俭让。革命是暴动，是一个阶级推翻另一个阶级的暴烈的行动。《湖南农民运动考察报告》（一九二七年三月）。什么人站在革命人民方面，他就是革命派，什么人站在帝国主义封建主义官僚资本主义方面，他就是反革命派。什么人只是口头上站在革命人民方面而在行动上则另是一样，他就是一个口头革命派，如果不但在口头上而且在行动上也站在革命人民方面，他就是一个完全的革命派。－－在中国人民政治协商会议第一届全国委员会第二次会议上的闭幕词。（一九五○年六月二十三日），一九五○年六月二十四日《人民日报》。如若不被敌人反对，那就不好了，那一定是同敌人同流合污了。如若被敌人反对，那就好了，那就证明我们同敌人划清界线了。《被敌人反对是好事而不是坏事》，一九三九年五月二十六日。在拿枪的敌人被消灭以后，不拿枪的敌人依然存在，他们必然地要和我们作拚死的斗争，我们决不可以轻视这些敌人。如果我们现在不是这样地提出问题和认识问题，我们就要犯极大的错误。《在中国共产党第七届中央委员会第二次全体会议上的报告》，（一九四九年三月五日），《毛泽东选集》第四卷第一四二八页。在我国，虽然社会主义改造，在所有制方面说来，已经基本完成，革命时期的大规模的急风暴雨式的群众阶级斗争已经基本结束，但是，被推翻的地主买办阶级的残余还是存在，资产阶级还是存在，小资产阶级刚刚在改造。阶级斗争并没有结束。无产阶级和资产阶级之间的阶级斗争，各派政治力量之间的阶级斗争，无产阶级和资产阶级之间在意识形态方面的阶级斗争，还是长期的、曲折的，有时甚至是很激烈的。无产阶级要按照自己的世界观改造世界，资产阶级也要按照自己的世界观改造世界。在这一方面，社会主义和资本主义之间谁胜谁负的问题还没有真正解决。《关于正确处理人民内部矛盾的问题》（一九五七年二月二十七日），人民出版社第二六－－二七页教条主义和修正主义都是违反马克思主义的。马克思主义一定要向前发展，要随着实践的发展而发展，不能停滞不前。停止了，老是那么一套，它就没有生命了。但是，马克思主义的基本思想原则又是不能违背的，违背了就要犯错误。用形而上学的观点看待马克思主义的基本原则，这是教条主义。否定马列主义的基本原则，否定马克思主义的普遍真理，这就是修正主义。修正主义是一种资产阶级思想。修正主义者抹杀社会主义和资本主义的区别，抹杀无产阶级专政和资产阶级专政的区别。他们所主张的，在实际上并不是社会主义路线，而是资本主义路线。在现在的情况下，修正主义是比教条主义更有害的东西。我们现在思想路线上的一个重要任务，就是要展开对修正主义的批判。《在中国共产党全国宣传工作会议上的讲话》（一九五七年三月十二日），人民出版社第二○－－二一页。修正主义，或者右倾机会主义，是一种资产阶级思潮，它比教条主义有更大的危险性。修正主义者，右倾机会主义者，口头上也挂着马克思主义，他们也在那里攻击“教条主义”。但是他们所攻击的正是马克思主义的最根本的东西。他们反对或者歪曲唯物论和辩证法，反对或者企图削弱人民民主专政和共产党的领导，反对或者企图削弱是改造和社会主义建设。在我国社会主义革命取得基本胜利以后，社会上还有一部分人梦想恢复资本主义制度，他们要从各个方面向工人阶级进行斗争，包括思想方面的斗争。而在这个斗争中，修正主义者就是他们最好的助手。《关于正确处理人民内部矛盾的问题》（一九五七年二月二十七日）人民出版社第二九－－三○页。";
}


- (uint32_t *)p_newLongChineseUnicodeCodePoints
{
    uint32_t codePoints[] = {
        0x9636, 0x7ea7, 0x6597, 0x4e89, 0xff0c, 0x4e00, 0x4e9b, 0x9636, 0x7ea7, 0x80dc, 0x5229, 0x4e86, 0xff0c,
        0x4e00, 0x4e9b, 0x9636, 0x7ea7, 0x6d88, 0x706d, 0x4e86, 0x3002, 0x8fd9, 0x5c31, 0x662f, 0x5386, 0x53f2,
        0xff0c, 0x8fd9, 0x5c31, 0x662f, 0x51e0, 0x5343, 0x5e74, 0x6765, 0x7684, 0x6587, 0x660e, 0x53f2, 0x3002,
        0x62ff, 0x8fd9, 0x4e2a, 0x89c2, 0x70b9, 0x89e3, 0x91ca, 0x5386, 0x53f2, 0x7684, 0x5c31, 0x53eb, 0x505a,
        0x5386, 0x53f2, 0x7684, 0x552f, 0x7269, 0x4e3b, 0x4e49, 0xff0c, 0x7ad9, 0x5728, 0x8fd9, 0x4e2a, 0x89c2,
        0x70b9, 0x7684, 0x53cd, 0x9762, 0x7684, 0x662f, 0x5386, 0x53f2, 0x7684, 0x552f, 0x5fc3, 0x4e3b, 0x4e49,
        0x3002, 0x300a, 0x4e22, 0x6389, 0x5e7b, 0x60f3, 0xff0c, 0x51c6, 0x5907, 0x6597, 0x4e89, 0x300b, 0xff08,
        0x4e00, 0x4e5d, 0x56db, 0x4e5d, 0x5e74, 0x516b, 0x6708, 0x5341, 0x56db, 0x65e5, 0xff09, 0xff0c, 0x300a,
        0x6bdb, 0x6cfd, 0x4e1c, 0x9009, 0x96c6, 0x300b, 0x7b2c, 0x56db, 0x5377, 0x7b2c, 0x4e00, 0x56db, 0x4e5d,
        0x4e00, 0x9875, 0x3002, 0x5730, 0x4e3b, 0x9636, 0x7ea7, 0x5bf9, 0x4e8e, 0x519c, 0x6c11, 0x7684, 0x6b8b,
        0x9177, 0x7684, 0x7ecf, 0x6d4e, 0x5265, 0x524a, 0x548c, 0x653f, 0x6cbb, 0x538b, 0x8feb, 0xff0c, 0x8feb,
        0x4f7f, 0x519c, 0x6c11, 0x591a, 0x6b21, 0x5730, 0x4e3e, 0x884c, 0x8d77, 0x4e49, 0xff0c, 0x4ee5, 0x53cd,
        0x6297, 0x5730, 0x4e3b, 0x9636, 0x7ea7, 0x7684, 0x7edf, 0x6cbb, 0x3002, 0x2026, 0x2026, 0x5728, 0x4e2d,
        0x56fd, 0x5c01, 0x5efa, 0x793e, 0x4f1a, 0x91cc, 0xff0c, 0x53ea, 0x6709, 0x8fd9, 0x4e9b, 0x519c, 0x6c11,
        0x7684, 0x9636, 0x7ea7, 0x6597, 0x4e89, 0x3001, 0x519c, 0x6c11, 0x7684, 0x8d77, 0x4e49, 0x548c, 0x519c,
        0x6c11, 0x7684, 0x6218, 0x4e89, 0xff0c, 0x624d, 0x662f, 0x5386, 0x53f2, 0x53d1, 0x5c55, 0x7684, 0x771f,
        0x6b63, 0x52a8, 0x529b, 0x3002, 0x300a, 0x4e2d, 0x56fd, 0x9769, 0x547d, 0x548c, 0x4e2d, 0x56fd, 0x5171,
        0x4ea7, 0x515a, 0x300b, 0xff08, 0x4e00, 0x4e5d, 0x4e09, 0x4e5d, 0x5e74, 0x5341, 0x4e8c, 0x6708, 0xff09,
        0x3002, 0x4eba, 0x6c11, 0x9760, 0x6211, 0x4eec, 0x53bb, 0x7ec4, 0x7ec7, 0xff0c, 0x4e2d, 0x56fd, 0x7684,
        0x53cd, 0x52a8, 0x5206, 0x5b50, 0xff0c, 0x9760, 0x6211, 0x4eec, 0x7ec4, 0x7ec7, 0x8d77, 0x4eba, 0x6c11,
        0x53bb, 0x628a, 0x4ed6, 0x6253, 0x5012, 0x3002, 0x51e1, 0x662f, 0x53cd, 0x52a8, 0x7684, 0x4e1c, 0x897f,
        0xff0c, 0x4f60, 0x4e0d, 0x6253, 0xff0c, 0x4ed6, 0x5c31, 0x4e0d, 0x5012, 0x3002, 0x8fd9, 0x4e5f, 0x548c,
        0x626b, 0x5730, 0x4e00, 0x6837, 0xff0c, 0x626b, 0x5e1a, 0x4e0d, 0x5230, 0xff0c, 0x7070, 0x5c18, 0x7167,
        0x4f8b, 0x4e0d, 0x4f1a, 0x81ea, 0x5df1, 0x8dd1, 0x6389, 0x3002, 0x300a, 0x6297, 0x65e5, 0x6218, 0x4e89,
        0x80dc, 0x5229, 0x540e, 0x7684, 0x65f6, 0x5c40, 0x548c, 0x6211, 0x4eec, 0x7684, 0x65b9, 0x9488, 0x300b,
        0xff08, 0x4e00, 0x4e5d, 0x56db, 0x4e94, 0x5e74, 0x516b, 0x6708, 0x5341, 0x4e09, 0x65e5, 0xff09, 0x300a,
        0x6bdb, 0x6cfd, 0x4e1c, 0x9009, 0x96c6, 0x300b, 0x7b2c, 0x56db, 0x5377, 0x4e00, 0x4e00, 0x4e09, 0x4e00,
        0x9875, 0x3002, 0x9769, 0x547d, 0x4e0d, 0x662f, 0x8bf7, 0x5ba2, 0x5403, 0x996d, 0xff0c, 0x4e0d, 0x662f,
        0x505a, 0x6587, 0x7ae0, 0xff0c, 0x4e0d, 0x662f, 0x7ed8, 0x753b, 0x7ee3, 0x82b1, 0xff0c, 0x4e0d, 0x80fd,
        0x90a3, 0x6837, 0x96c5, 0x81f4, 0xff0c, 0x90a3, 0x6837, 0x4ece, 0x5bb9, 0x4e0d, 0x8feb, 0xff0c, 0x6587,
        0x8d28, 0x5f6c, 0x5f6c, 0xff0c, 0x90a3, 0x6837, 0x6e29, 0x826f, 0x606d, 0x4fed, 0x8ba9, 0x3002, 0x9769,
        0x547d, 0x662f, 0x66b4, 0x52a8, 0xff0c, 0x662f, 0x4e00, 0x4e2a, 0x9636, 0x7ea7, 0x63a8, 0x7ffb, 0x53e6,
        0x4e00, 0x4e2a, 0x9636, 0x7ea7, 0x7684, 0x66b4, 0x70c8, 0x7684, 0x884c, 0x52a8, 0x3002, 0x300a, 0x6e56,
        0x5357, 0x519c, 0x6c11, 0x8fd0, 0x52a8, 0x8003, 0x5bdf, 0x62a5, 0x544a, 0x300b, 0xff08, 0x4e00, 0x4e5d,
        0x4e8c, 0x4e03, 0x5e74, 0x4e09, 0x6708, 0xff09, 0x3002, 0x4ec0, 0x4e48, 0x4eba, 0x7ad9, 0x5728, 0x9769,
        0x547d, 0x4eba, 0x6c11, 0x65b9, 0x9762, 0xff0c, 0x4ed6, 0x5c31, 0x662f, 0x9769, 0x547d, 0x6d3e, 0xff0c,
        0x4ec0, 0x4e48, 0x4eba, 0x7ad9, 0x5728, 0x5e1d, 0x56fd, 0x4e3b, 0x4e49, 0x5c01, 0x5efa, 0x4e3b, 0x4e49,
        0x5b98, 0x50da, 0x8d44, 0x672c, 0x4e3b, 0x4e49, 0x65b9, 0x9762, 0xff0c, 0x4ed6, 0x5c31, 0x662f, 0x53cd,
        0x9769, 0x547d, 0x6d3e, 0x3002, 0x4ec0, 0x4e48, 0x4eba, 0x53ea, 0x662f, 0x53e3, 0x5934, 0x4e0a, 0x7ad9,
        0x5728, 0x9769, 0x547d, 0x4eba, 0x6c11, 0x65b9, 0x9762, 0x800c, 0x5728, 0x884c, 0x52a8, 0x4e0a, 0x5219,
        0x53e6, 0x662f, 0x4e00, 0x6837, 0xff0c, 0x4ed6, 0x5c31, 0x662f, 0x4e00, 0x4e2a, 0x53e3, 0x5934, 0x9769,
        0x547d, 0x6d3e, 0xff0c, 0x5982, 0x679c, 0x4e0d, 0x4f46, 0x5728, 0x53e3, 0x5934, 0x4e0a, 0x800c, 0x4e14,
        0x5728, 0x884c, 0x52a8, 0x4e0a, 0x4e5f, 0x7ad9, 0x5728, 0x9769, 0x547d, 0x4eba, 0x6c11, 0x65b9, 0x9762,
        0xff0c, 0x4ed6, 0x5c31, 0x662f, 0x4e00, 0x4e2a, 0x5b8c, 0x5168, 0x7684, 0x9769, 0x547d, 0x6d3e, 0x3002,
        0xff0d, 0xff0d, 0x5728, 0x4e2d, 0x56fd, 0x4eba, 0x6c11, 0x653f, 0x6cbb, 0x534f, 0x5546, 0x4f1a, 0x8bae,
        0x7b2c, 0x4e00, 0x5c4a, 0x5168, 0x56fd, 0x59d4, 0x5458, 0x4f1a, 0x7b2c, 0x4e8c, 0x6b21, 0x4f1a, 0x8bae,
        0x4e0a, 0x7684, 0x95ed, 0x5e55, 0x8bcd, 0x3002, 0xff08, 0x4e00, 0x4e5d, 0x4e94, 0x25cb, 0x5e74, 0x516d,
        0x6708, 0x4e8c, 0x5341, 0x4e09, 0x65e5, 0xff09, 0xff0c, 0x4e00, 0x4e5d, 0x4e94, 0x25cb, 0x5e74, 0x516d,
        0x6708, 0x4e8c, 0x5341, 0x56db, 0x65e5, 0x300a, 0x4eba, 0x6c11, 0x65e5, 0x62a5, 0x300b, 0x3002, 0x5982,
        0x82e5, 0x4e0d, 0x88ab, 0x654c, 0x4eba, 0x53cd, 0x5bf9, 0xff0c, 0x90a3, 0x5c31, 0x4e0d, 0x597d, 0x4e86,
        0xff0c, 0x90a3, 0x4e00, 0x5b9a, 0x662f, 0x540c, 0x654c, 0x4eba, 0x540c, 0x6d41, 0x5408, 0x6c61, 0x4e86,
        0x3002, 0x5982, 0x82e5, 0x88ab, 0x654c, 0x4eba, 0x53cd, 0x5bf9, 0xff0c, 0x90a3, 0x5c31, 0x597d, 0x4e86,
        0xff0c, 0x90a3, 0x5c31, 0x8bc1, 0x660e, 0x6211, 0x4eec, 0x540c, 0x654c, 0x4eba, 0x5212, 0x6e05, 0x754c,
        0x7ebf, 0x4e86, 0x3002, 0x300a, 0x88ab, 0x654c, 0x4eba, 0x53cd, 0x5bf9, 0x662f, 0x597d, 0x4e8b, 0x800c,
        0x4e0d, 0x662f, 0x574f, 0x4e8b, 0x300b, 0xff0c, 0x4e00, 0x4e5d, 0x4e09, 0x4e5d, 0x5e74, 0x4e94, 0x6708,
        0x4e8c, 0x5341, 0x516d, 0x65e5, 0x3002, 0x5728, 0x62ff, 0x67aa, 0x7684, 0x654c, 0x4eba, 0x88ab, 0x6d88,
        0x706d, 0x4ee5, 0x540e, 0xff0c, 0x4e0d, 0x62ff, 0x67aa, 0x7684, 0x654c, 0x4eba, 0x4f9d, 0x7136, 0x5b58,
        0x5728, 0xff0c, 0x4ed6, 0x4eec, 0x5fc5, 0x7136, 0x5730, 0x8981, 0x548c, 0x6211, 0x4eec, 0x4f5c, 0x62da,
        0x6b7b, 0x7684, 0x6597, 0x4e89, 0xff0c, 0x6211, 0x4eec, 0x51b3, 0x4e0d, 0x53ef, 0x4ee5, 0x8f7b, 0x89c6,
        0x8fd9, 0x4e9b, 0x654c, 0x4eba, 0x3002, 0x5982, 0x679c, 0x6211, 0x4eec, 0x73b0, 0x5728, 0x4e0d, 0x662f,
        0x8fd9, 0x6837, 0x5730, 0x63d0, 0x51fa, 0x95ee, 0x9898, 0x548c, 0x8ba4, 0x8bc6, 0x95ee, 0x9898, 0xff0c,
        0x6211, 0x4eec, 0x5c31, 0x8981, 0x72af, 0x6781, 0x5927, 0x7684, 0x9519, 0x8bef, 0x3002, 0x300a, 0x5728,
        0x4e2d, 0x56fd, 0x5171, 0x4ea7, 0x515a, 0x7b2c, 0x4e03, 0x5c4a, 0x4e2d, 0x592e, 0x59d4, 0x5458, 0x4f1a,
        0x7b2c, 0x4e8c, 0x6b21, 0x5168, 0x4f53, 0x4f1a, 0x8bae, 0x4e0a, 0x7684, 0x62a5, 0x544a, 0x300b, 0xff0c,
        0xff08, 0x4e00, 0x4e5d, 0x56db, 0x4e5d, 0x5e74, 0x4e09, 0x6708, 0x4e94, 0x65e5, 0xff09, 0xff0c, 0x300a,
        0x6bdb, 0x6cfd, 0x4e1c, 0x9009, 0x96c6, 0x300b, 0x7b2c, 0x56db, 0x5377, 0x7b2c, 0x4e00, 0x56db, 0x4e8c,
        0x516b, 0x9875, 0x3002, 0x5728, 0x6211, 0x56fd, 0xff0c, 0x867d, 0x7136, 0x793e, 0x4f1a, 0x4e3b, 0x4e49,
        0x6539, 0x9020, 0xff0c, 0x5728, 0x6240, 0x6709, 0x5236, 0x65b9, 0x9762, 0x8bf4, 0x6765, 0xff0c, 0x5df2,
        0x7ecf, 0x57fa, 0x672c, 0x5b8c, 0x6210, 0xff0c, 0x9769, 0x547d, 0x65f6, 0x671f, 0x7684, 0x5927, 0x89c4,
        0x6a21, 0x7684, 0x6025, 0x98ce, 0x66b4, 0x96e8, 0x5f0f, 0x7684, 0x7fa4, 0x4f17, 0x9636, 0x7ea7, 0x6597,
        0x4e89, 0x5df2, 0x7ecf, 0x57fa, 0x672c, 0x7ed3, 0x675f, 0xff0c, 0x4f46, 0x662f, 0xff0c, 0x88ab, 0x63a8,
        0x7ffb, 0x7684, 0x5730, 0x4e3b, 0x4e70, 0x529e, 0x9636, 0x7ea7, 0x7684, 0x6b8b, 0x4f59, 0x8fd8, 0x662f,
        0x5b58, 0x5728, 0xff0c, 0x8d44, 0x4ea7, 0x9636, 0x7ea7, 0x8fd8, 0x662f, 0x5b58, 0x5728, 0xff0c, 0x5c0f,
        0x8d44, 0x4ea7, 0x9636, 0x7ea7, 0x521a, 0x521a, 0x5728, 0x6539, 0x9020, 0x3002, 0x9636, 0x7ea7, 0x6597,
        0x4e89, 0x5e76, 0x6ca1, 0x6709, 0x7ed3, 0x675f, 0x3002, 0x65e0, 0x4ea7, 0x9636, 0x7ea7, 0x548c, 0x8d44,
        0x4ea7, 0x9636, 0x7ea7, 0x4e4b, 0x95f4, 0x7684, 0x9636, 0x7ea7, 0x6597, 0x4e89, 0xff0c, 0x5404, 0x6d3e,
        0x653f, 0x6cbb, 0x529b, 0x91cf, 0x4e4b, 0x95f4, 0x7684, 0x9636, 0x7ea7, 0x6597, 0x4e89, 0xff0c, 0x65e0,
        0x4ea7, 0x9636, 0x7ea7, 0x548c, 0x8d44, 0x4ea7, 0x9636, 0x7ea7, 0x4e4b, 0x95f4, 0x5728, 0x610f, 0x8bc6,
        0x5f62, 0x6001, 0x65b9, 0x9762, 0x7684, 0x9636, 0x7ea7, 0x6597, 0x4e89, 0xff0c, 0x8fd8, 0x662f, 0x957f,
        0x671f, 0x7684, 0x3001, 0x66f2, 0x6298, 0x7684, 0xff0c, 0x6709, 0x65f6, 0x751a, 0x81f3, 0x662f, 0x5f88,
        0x6fc0, 0x70c8, 0x7684, 0x3002, 0x65e0, 0x4ea7, 0x9636, 0x7ea7, 0x8981, 0x6309, 0x7167, 0x81ea, 0x5df1,
        0x7684, 0x4e16, 0x754c, 0x89c2, 0x6539, 0x9020, 0x4e16, 0x754c, 0xff0c, 0x8d44, 0x4ea7, 0x9636, 0x7ea7,
        0x4e5f, 0x8981, 0x6309, 0x7167, 0x81ea, 0x5df1, 0x7684, 0x4e16, 0x754c, 0x89c2, 0x6539, 0x9020, 0x4e16,
        0x754c, 0x3002, 0x5728, 0x8fd9, 0x4e00, 0x65b9, 0x9762, 0xff0c, 0x793e, 0x4f1a, 0x4e3b, 0x4e49, 0x548c,
        0x8d44, 0x672c, 0x4e3b, 0x4e49, 0x4e4b, 0x95f4, 0x8c01, 0x80dc, 0x8c01, 0x8d1f, 0x7684, 0x95ee, 0x9898,
        0x8fd8, 0x6ca1, 0x6709, 0x771f, 0x6b63, 0x89e3, 0x51b3, 0x3002, 0x300a, 0x5173, 0x4e8e, 0x6b63, 0x786e,
        0x5904, 0x7406, 0x4eba, 0x6c11, 0x5185, 0x90e8, 0x77db, 0x76fe, 0x7684, 0x95ee, 0x9898, 0x300b, 0xff08,
        0x4e00, 0x4e5d, 0x4e94, 0x4e03, 0x5e74, 0x4e8c, 0x6708, 0x4e8c, 0x5341, 0x4e03, 0x65e5, 0xff09, 0xff0c,
        0x4eba, 0x6c11, 0x51fa, 0x7248, 0x793e, 0x7b2c, 0x4e8c, 0x516d, 0xff0d, 0xff0d, 0x4e8c, 0x4e03, 0x9875,
        0x6559, 0x6761, 0x4e3b, 0x4e49, 0x548c, 0x4fee, 0x6b63, 0x4e3b, 0x4e49, 0x90fd, 0x662f, 0x8fdd, 0x53cd,
        0x9a6c, 0x514b, 0x601d, 0x4e3b, 0x4e49, 0x7684, 0x3002, 0x9a6c, 0x514b, 0x601d, 0x4e3b, 0x4e49, 0x4e00,
        0x5b9a, 0x8981, 0x5411, 0x524d, 0x53d1, 0x5c55, 0xff0c, 0x8981, 0x968f, 0x7740, 0x5b9e, 0x8df5, 0x7684,
        0x53d1, 0x5c55, 0x800c, 0x53d1, 0x5c55, 0xff0c, 0x4e0d, 0x80fd, 0x505c, 0x6ede, 0x4e0d, 0x524d, 0x3002,
        0x505c, 0x6b62, 0x4e86, 0xff0c, 0x8001, 0x662f, 0x90a3, 0x4e48, 0x4e00, 0x5957, 0xff0c, 0x5b83, 0x5c31,
        0x6ca1, 0x6709, 0x751f, 0x547d, 0x4e86, 0x3002, 0x4f46, 0x662f, 0xff0c, 0x9a6c, 0x514b, 0x601d, 0x4e3b,
        0x4e49, 0x7684, 0x57fa, 0x672c, 0x601d, 0x60f3, 0x539f, 0x5219, 0x53c8, 0x662f, 0x4e0d, 0x80fd, 0x8fdd,
        0x80cc, 0x7684, 0xff0c, 0x8fdd, 0x80cc, 0x4e86, 0x5c31, 0x8981, 0x72af, 0x9519, 0x8bef, 0x3002, 0x7528,
        0x5f62, 0x800c, 0x4e0a, 0x5b66, 0x7684, 0x89c2, 0x70b9, 0x770b, 0x5f85, 0x9a6c, 0x514b, 0x601d, 0x4e3b,
        0x4e49, 0x7684, 0x57fa, 0x672c, 0x539f, 0x5219, 0xff0c, 0x8fd9, 0x662f, 0x6559, 0x6761, 0x4e3b, 0x4e49,
        0x3002, 0x5426, 0x5b9a, 0x9a6c, 0x5217, 0x4e3b, 0x4e49, 0x7684, 0x57fa, 0x672c, 0x539f, 0x5219, 0xff0c,
        0x5426, 0x5b9a, 0x9a6c, 0x514b, 0x601d, 0x4e3b, 0x4e49, 0x7684, 0x666e, 0x904d, 0x771f, 0x7406, 0xff0c,
        0x8fd9, 0x5c31, 0x662f, 0x4fee, 0x6b63, 0x4e3b, 0x4e49, 0x3002, 0x4fee, 0x6b63, 0x4e3b, 0x4e49, 0x662f,
        0x4e00, 0x79cd, 0x8d44, 0x4ea7, 0x9636, 0x7ea7, 0x601d, 0x60f3, 0x3002, 0x4fee, 0x6b63, 0x4e3b, 0x4e49,
        0x8005, 0x62b9, 0x6740, 0x793e, 0x4f1a, 0x4e3b, 0x4e49, 0x548c, 0x8d44, 0x672c, 0x4e3b, 0x4e49, 0x7684,
        0x533a, 0x522b, 0xff0c, 0x62b9, 0x6740, 0x65e0, 0x4ea7, 0x9636, 0x7ea7, 0x4e13, 0x653f, 0x548c, 0x8d44,
        0x4ea7, 0x9636, 0x7ea7, 0x4e13, 0x653f, 0x7684, 0x533a, 0x522b, 0x3002, 0x4ed6, 0x4eec, 0x6240, 0x4e3b,
        0x5f20, 0x7684, 0xff0c, 0x5728, 0x5b9e, 0x9645, 0x4e0a, 0x5e76, 0x4e0d, 0x662f, 0x793e, 0x4f1a, 0x4e3b,
        0x4e49, 0x8def, 0x7ebf, 0xff0c, 0x800c, 0x662f, 0x8d44, 0x672c, 0x4e3b, 0x4e49, 0x8def, 0x7ebf, 0x3002,
        0x5728, 0x73b0, 0x5728, 0x7684, 0x60c5, 0x51b5, 0x4e0b, 0xff0c, 0x4fee, 0x6b63, 0x4e3b, 0x4e49, 0x662f,
        0x6bd4, 0x6559, 0x6761, 0x4e3b, 0x4e49, 0x66f4, 0x6709, 0x5bb3, 0x7684, 0x4e1c, 0x897f, 0x3002, 0x6211,
        0x4eec, 0x73b0, 0x5728, 0x601d, 0x60f3, 0x8def, 0x7ebf, 0x4e0a, 0x7684, 0x4e00, 0x4e2a, 0x91cd, 0x8981,
        0x4efb, 0x52a1, 0xff0c, 0x5c31, 0x662f, 0x8981, 0x5c55, 0x5f00, 0x5bf9, 0x4fee, 0x6b63, 0x4e3b, 0x4e49,
        0x7684, 0x6279, 0x5224, 0x3002, 0x300a, 0x5728, 0x4e2d, 0x56fd, 0x5171, 0x4ea7, 0x515a, 0x5168, 0x56fd,
        0x5ba3, 0x4f20, 0x5de5, 0x4f5c, 0x4f1a, 0x8bae, 0x4e0a, 0x7684, 0x8bb2, 0x8bdd, 0x300b, 0xff08, 0x4e00,
        0x4e5d, 0x4e94, 0x4e03, 0x5e74, 0x4e09, 0x6708, 0x5341, 0x4e8c, 0x65e5, 0xff09, 0xff0c, 0x4eba, 0x6c11,
        0x51fa, 0x7248, 0x793e, 0x7b2c, 0x4e8c, 0x25cb, 0xff0d, 0xff0d, 0x4e8c, 0x4e00, 0x9875, 0x3002, 0x4fee,
        0x6b63, 0x4e3b, 0x4e49, 0xff0c, 0x6216, 0x8005, 0x53f3, 0x503e, 0x673a, 0x4f1a, 0x4e3b, 0x4e49, 0xff0c,
        0x662f, 0x4e00, 0x79cd, 0x8d44, 0x4ea7, 0x9636, 0x7ea7, 0x601d, 0x6f6e, 0xff0c, 0x5b83, 0x6bd4, 0x6559,
        0x6761, 0x4e3b, 0x4e49, 0x6709, 0x66f4, 0x5927, 0x7684, 0x5371, 0x9669, 0x6027, 0x3002, 0x4fee, 0x6b63,
        0x4e3b, 0x4e49, 0x8005, 0xff0c, 0x53f3, 0x503e, 0x673a, 0x4f1a, 0x4e3b, 0x4e49, 0x8005, 0xff0c, 0x53e3,
        0x5934, 0x4e0a, 0x4e5f, 0x6302, 0x7740, 0x9a6c, 0x514b, 0x601d, 0x4e3b, 0x4e49, 0xff0c, 0x4ed6, 0x4eec,
        0x4e5f, 0x5728, 0x90a3, 0x91cc, 0x653b, 0x51fb, 0x201c, 0x6559, 0x6761, 0x4e3b, 0x4e49, 0x201d, 0x3002,
        0x4f46, 0x662f, 0x4ed6, 0x4eec, 0x6240, 0x653b, 0x51fb, 0x7684, 0x6b63, 0x662f, 0x9a6c, 0x514b, 0x601d,
        0x4e3b, 0x4e49, 0x7684, 0x6700, 0x6839, 0x672c, 0x7684, 0x4e1c, 0x897f, 0x3002, 0x4ed6, 0x4eec, 0x53cd,
        0x5bf9, 0x6216, 0x8005, 0x6b6a, 0x66f2, 0x552f, 0x7269, 0x8bba, 0x548c, 0x8fa9, 0x8bc1, 0x6cd5, 0xff0c,
        0x53cd, 0x5bf9, 0x6216, 0x8005, 0x4f01, 0x56fe, 0x524a, 0x5f31, 0x4eba, 0x6c11, 0x6c11, 0x4e3b, 0x4e13,
        0x653f, 0x548c, 0x5171, 0x4ea7, 0x515a, 0x7684, 0x9886, 0x5bfc, 0xff0c, 0x53cd, 0x5bf9, 0x6216, 0x8005,
        0x4f01, 0x56fe, 0x524a, 0x5f31, 0x662f, 0x6539, 0x9020, 0x548c, 0x793e, 0x4f1a, 0x4e3b, 0x4e49, 0x5efa,
        0x8bbe, 0x3002, 0x5728, 0x6211, 0x56fd, 0x793e, 0x4f1a, 0x4e3b, 0x4e49, 0x9769, 0x547d, 0x53d6, 0x5f97,
        0x57fa, 0x672c, 0x80dc, 0x5229, 0x4ee5, 0x540e, 0xff0c, 0x793e, 0x4f1a, 0x4e0a, 0x8fd8, 0x6709, 0x4e00,
        0x90e8, 0x5206, 0x4eba, 0x68a6, 0x60f3, 0x6062, 0x590d, 0x8d44, 0x672c, 0x4e3b, 0x4e49, 0x5236, 0x5ea6,
        0xff0c, 0x4ed6, 0x4eec, 0x8981, 0x4ece, 0x5404, 0x4e2a, 0x65b9, 0x9762, 0x5411, 0x5de5, 0x4eba, 0x9636,
        0x7ea7, 0x8fdb, 0x884c, 0x6597, 0x4e89, 0xff0c, 0x5305, 0x62ec, 0x601d, 0x60f3, 0x65b9, 0x9762, 0x7684,
        0x6597, 0x4e89, 0x3002, 0x800c, 0x5728, 0x8fd9, 0x4e2a, 0x6597, 0x4e89, 0x4e2d, 0xff0c, 0x4fee, 0x6b63,
        0x4e3b, 0x4e49, 0x8005, 0x5c31, 0x662f, 0x4ed6, 0x4eec, 0x6700, 0x597d, 0x7684, 0x52a9, 0x624b, 0x3002,
        0x300a, 0x5173, 0x4e8e, 0x6b63, 0x786e, 0x5904, 0x7406, 0x4eba, 0x6c11, 0x5185, 0x90e8, 0x77db, 0x76fe,
        0x7684, 0x95ee, 0x9898, 0x300b, 0xff08, 0x4e00, 0x4e5d, 0x4e94, 0x4e03, 0x5e74, 0x4e8c, 0x6708, 0x4e8c,
        0x5341, 0x4e03, 0x65e5, 0xff09, 0x4eba, 0x6c11, 0x51fa, 0x7248, 0x793e, 0x7b2c, 0x4e8c, 0x4e5d, 0xff0d,
        0xff0d, 0x4e09, 0x25cb, 0x9875, 0x3002};

    size_t count = sizeof(codePoints) / sizeof(uint32_t);
    uint32_t *new = calloc(count, sizeof(uint32_t));
    memcpy(new, codePoints, sizeof(codePoints));

    return new;
}


@end
