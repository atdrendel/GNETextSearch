//
//  GNEMutableStringTests.m
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/11/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "stringbuf.h"


// ------------------------------------------------------------------------------------------


typedef struct tsearch_stringbuf
{
    char *buffer;
    size_t capacity;
    size_t length;
} tsearch_stringbuf;

size_t _tsearch_stringbuf_get_max_char_count(tsearch_stringbuf_ptr ptr);


// ------------------------------------------------------------------------------------------


@interface GNEMutableStringTests : XCTestCase
{
    tsearch_stringbuf_ptr _mutableStringPtr;
}

@end


// ------------------------------------------------------------------------------------------


@implementation GNEMutableStringTests


// ------------------------------------------------------------------------------------------
#pragma mark - Set Up / Tear Down
// ------------------------------------------------------------------------------------------
- (void)setUp
{
    [super setUp];
    _mutableStringPtr = tsearch_stringbuf_init();
}


- (void)tearDown
{
    tsearch_stringbuf_free(_mutableStringPtr);
    [super tearDown];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Initialization
// ------------------------------------------------------------------------------------------
- (void)testInitialization_Default_NotNilAndHasDefaultValues
{
    XCTAssertTrue(_mutableStringPtr != NULL);
    XCTAssertTrue(_mutableStringPtr->buffer != NULL);
    XCTAssertEqual(_mutableStringPtr->capacity, 5 * sizeof(char));
    XCTAssertEqual(_mutableStringPtr->length, 0);
}


- (void)testInitialization_WithCStringABCD_NotNilAndContainsString
{
    tsearch_stringbuf_free(_mutableStringPtr);
    _mutableStringPtr = NULL;

    const char *cString = "ABCD";
    size_t length = 4;
    _mutableStringPtr = tsearch_stringbuf_init_with_cstring(cString, length);
    XCTAssertTrue(_mutableStringPtr != NULL);
    XCTAssertTrue(_mutableStringPtr->buffer != NULL);
    [self assertCString:cString isEqualToCString:_mutableStringPtr->buffer length:length];
    XCTAssertEqual(_mutableStringPtr->capacity, 5 * sizeof(char)); // Size should not have changed.
    XCTAssertEqual(_mutableStringPtr->length, length);
}


- (void)testInitialization_WithCStringABCDE_NotNilAndContainsString
{
    tsearch_stringbuf_free(_mutableStringPtr);
    _mutableStringPtr = NULL;

    const char *cString = "ABCDE";
    size_t length = 5;
    _mutableStringPtr = tsearch_stringbuf_init_with_cstring(cString, length);
    XCTAssertTrue(_mutableStringPtr != NULL);
    XCTAssertTrue(_mutableStringPtr->buffer != NULL);
    [self assertCString:cString isEqualToCString:_mutableStringPtr->buffer length:length];
    XCTAssertEqual(_mutableStringPtr->capacity, 10 * sizeof(char)); // Size should have doubled.
    XCTAssertEqual(_mutableStringPtr->length, length);
}


- (void)testInitialization_WithCStringABCDEFGHIJK_NotNilAndContainsString
{
    tsearch_stringbuf_free(_mutableStringPtr);
    _mutableStringPtr = NULL;

    const char *cString = "ABCDEFGHIJK";
    size_t length = 11;
    _mutableStringPtr = tsearch_stringbuf_init_with_cstring(cString, length);
    XCTAssertTrue(_mutableStringPtr != NULL);
    XCTAssertTrue(_mutableStringPtr->buffer != NULL);
    [self assertCString:cString isEqualToCString:_mutableStringPtr->buffer length:length];
    XCTAssertEqual(_mutableStringPtr->capacity, 11 * sizeof(char)); // Size should switched to new size.
    XCTAssertEqual(_mutableStringPtr->length, length);
}


- (void)testInitialization_WithLongChineseCString_NotNilAndContainsString
{
    tsearch_stringbuf_free(_mutableStringPtr);
    _mutableStringPtr = NULL;

    const char *cString = [self longChineseString].UTF8String;
    size_t length = [[self longChineseString] lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    _mutableStringPtr = tsearch_stringbuf_init_with_cstring(cString, length);
    XCTAssertTrue(_mutableStringPtr != NULL);
    XCTAssertTrue(_mutableStringPtr->buffer != NULL);
    [self assertCString:cString isEqualToCString:_mutableStringPtr->buffer length:length];
    XCTAssertEqual(_mutableStringPtr->capacity, length * sizeof(char)); // Size should switched to new size.
    XCTAssertEqual(_mutableStringPtr->length, length);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Length
// ------------------------------------------------------------------------------------------
- (void)testLength_EmptyCString_0
{
    XCTAssertEqual(0, _mutableStringPtr->length);
    XCTAssertEqual(0, tsearch_stringbuf_get_len(_mutableStringPtr));
}


- (void)testLength_ABCD_4
{
    const char *cString = "ABCD";
    size_t length = 4;
    tsearch_stringbuf_append_cstring(_mutableStringPtr, cString, length);
    XCTAssertEqual(length, _mutableStringPtr->length);
    XCTAssertEqual(length, tsearch_stringbuf_get_len(_mutableStringPtr));
}


- (void)testLength_ABCDE_5
{
    const char *cString = "ABCDE";
    size_t length = 5;
    tsearch_stringbuf_append_cstring(_mutableStringPtr, cString, length);
    XCTAssertEqual(length, _mutableStringPtr->length);
    XCTAssertEqual(length, tsearch_stringbuf_get_len(_mutableStringPtr));
}


- (void)testLength_LongChineseString_5397
{
    const char *cString = [self longChineseString].UTF8String;
    size_t length = [[self longChineseString] lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    tsearch_stringbuf_append_cstring(_mutableStringPtr, cString, length);
    XCTAssertEqual(length, _mutableStringPtr->length);
    XCTAssertEqual(length, tsearch_stringbuf_get_len(_mutableStringPtr));
}


// ------------------------------------------------------------------------------------------
#pragma mark - Get Char
// ------------------------------------------------------------------------------------------
- (void)testGetChar_EachCharInABCDE_CorrectCharAtCorrectIndex
{
    const char *cString = "ABCDE";
    size_t length = 5;
    tsearch_stringbuf_append_cstring(_mutableStringPtr, cString, length);

    for (size_t i = 0; i < length; i++)
    {
        XCTAssertEqual(cString[i], tsearch_stringbuf_get_char_at_idx(_mutableStringPtr, i));
    }
}


- (void)testGetChar_EachCharInChineseString_CorrectCharAtCorrectIndex
{
    const char *cString = [self longChineseString].UTF8String;
    size_t length = [[self longChineseString] lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    tsearch_stringbuf_append_cstring(_mutableStringPtr, cString, length);

    for (size_t i = 0; i < length; i++)
    {
        XCTAssertEqual(cString[i], tsearch_stringbuf_get_char_at_idx(_mutableStringPtr, i));
    }
}


- (void)testGetChar_NullPointer_NullChar
{
    XCTAssertEqual('\0', tsearch_stringbuf_get_char_at_idx(NULL, 1));
}


- (void)testGetChar_PastIndex_NullChar
{
    const char *cString = "ABCDE";
    size_t length = 5;
    tsearch_stringbuf_append_cstring(_mutableStringPtr, cString, length);

    XCTAssertEqual('\0', tsearch_stringbuf_get_char_at_idx(_mutableStringPtr, length));
}


// ------------------------------------------------------------------------------------------
#pragma mark - Appending
// ------------------------------------------------------------------------------------------
- (void)testAppending_FiveOneCharStrings_CorrectLengthAndContents
{
    XCTAssertEqual(0, _mutableStringPtr->length);
    XCTAssertEqual(5, _mutableStringPtr->capacity);
    XCTAssertEqual(5, _tsearch_stringbuf_get_max_char_count(_mutableStringPtr));

    const char *cString = "ABCDE";
    size_t length = 5;
    for (size_t i = 0; i < length; i++)
    {
        tsearch_stringbuf_append_cstring(_mutableStringPtr, (cString + i), 1);
    }

    XCTAssertEqual(length, _mutableStringPtr->length);
    XCTAssertEqual(length, tsearch_stringbuf_get_len(_mutableStringPtr));
    XCTAssertEqual(10, _mutableStringPtr->capacity);
    XCTAssertEqual(10, _tsearch_stringbuf_get_max_char_count(_mutableStringPtr));
    XCTAssertEqual(0, memcmp(cString, _mutableStringPtr->buffer, length));
    [self assertCString:cString isEqualToCString:tsearch_stringbuf_copy_cstring(_mutableStringPtr) length:length];
}


- (void)testAppending_FiveOneLongChineseStrings_CorrectLengthAndContents
{
    XCTAssertEqual(0, _mutableStringPtr->length);
    XCTAssertEqual(5, _mutableStringPtr->capacity);
    XCTAssertEqual(5, _tsearch_stringbuf_get_max_char_count(_mutableStringPtr));

    size_t count = 5;

    NSMutableString *targetString = [NSMutableString string];
    for (size_t i = 0; i < count; i++)
    {
        NSString *string = [NSString stringWithFormat:@"%@\n", [self longChineseString]];
        size_t length = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        tsearch_stringbuf_append_cstring(_mutableStringPtr, string.UTF8String, length);
        [targetString appendString:string];
    }

    size_t length = [targetString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    XCTAssertEqual(length, _mutableStringPtr->length);
    XCTAssertEqual(length, tsearch_stringbuf_get_len(_mutableStringPtr));
    XCTAssertEqual(43184, _mutableStringPtr->capacity);
    XCTAssertEqual(43184, _tsearch_stringbuf_get_max_char_count(_mutableStringPtr));
    XCTAssertEqual(0, memcmp(targetString.UTF8String, _mutableStringPtr->buffer, length));
    [self assertCString:targetString.UTF8String isEqualToCString:tsearch_stringbuf_copy_cstring(_mutableStringPtr) length:length];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Copy Contents
// ------------------------------------------------------------------------------------------
- (void)testCopyContents_ABCDE_PerfectCopy
{
    const char *cString = "ABCDE";
    size_t length = 5;
    tsearch_stringbuf_append_cstring(_mutableStringPtr, cString, length);

    const char *copy = tsearch_stringbuf_copy_cstring(_mutableStringPtr);
    XCTAssertEqual(0, memcmp(cString, copy, length));
    XCTAssertEqual(length, strlen(copy));
    XCTAssertEqual('\0', copy[strlen(copy)]);

    free((void *)copy);
}


- (void)testCopyContents_ChineseString_PerfectCopy
{
    const char *cString = [self longChineseString].UTF8String;
    size_t length = [[self longChineseString] lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    tsearch_stringbuf_append_cstring(_mutableStringPtr, cString, length);

    const char *copy = tsearch_stringbuf_copy_cstring(_mutableStringPtr);
    XCTAssertEqual(0, memcmp(cString, copy, length));
    XCTAssertEqual(length, strlen(copy));
    XCTAssertEqual('\0', copy[strlen(copy)]);

    free((void *)copy);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Helpers
// ------------------------------------------------------------------------------------------
- (void)assertCString:(const char *)cString1 isEqualToCString:(const char *)cString2 length:(size_t)length
{
    for (size_t i = 0; i < length; i++)
    {
        XCTAssertEqual(cString1[i], cString2[i]);
    }
}


- (NSString *)longChineseString
{
    return @"阶级斗争，一些阶级胜利了，一些阶级消灭了。这就是历史，这就是几千年来的文明史。拿这个观点解释历史的就叫做历史的唯物主义，站在这个观点的反面的是历史的唯心主义。《丢掉幻想，准备斗争》（一九四九年八月十四日），《毛泽东选集》第四卷第一四九一页。地主阶级对于农民的残酷的经济剥削和政治压迫，迫使农民多次地举行起义，以反抗地主阶级的统治。……在中国封建社会里，只有这些农民的阶级斗争、农民的起义和农民的战争，才是历史发展的真正动力。《中国革命和中国共产党》（一九三九年十二月）。人民靠我们去组织，中国的反动分子，靠我们组织起人民去把他打倒。凡是反动的东西，你不打，他就不倒。这也和扫地一样，扫帚不到，灰尘照例不会自己跑掉。《抗日战争胜利后的时局和我们的方针》（一九四五年八月十三日）《毛泽东选集》第四卷一一三一页。革命不是请客吃饭，不是做文章，不是绘画绣花，不能那样雅致，那样从容不迫，文质彬彬，那样温良恭俭让。革命是暴动，是一个阶级推翻另一个阶级的暴烈的行动。《湖南农民运动考察报告》（一九二七年三月）。什么人站在革命人民方面，他就是革命派，什么人站在帝国主义封建主义官僚资本主义方面，他就是反革命派。什么人只是口头上站在革命人民方面而在行动上则另是一样，他就是一个口头革命派，如果不但在口头上而且在行动上也站在革命人民方面，他就是一个完全的革命派。－－在中国人民政治协商会议第一届全国委员会第二次会议上的闭幕词。（一九五○年六月二十三日），一九五○年六月二十四日《人民日报》。如若不被敌人反对，那就不好了，那一定是同敌人同流合污了。如若被敌人反对，那就好了，那就证明我们同敌人划清界线了。《被敌人反对是好事而不是坏事》，一九三九年五月二十六日。在拿枪的敌人被消灭以后，不拿枪的敌人依然存在，他们必然地要和我们作拚死的斗争，我们决不可以轻视这些敌人。如果我们现在不是这样地提出问题和认识问题，我们就要犯极大的错误。《在中国共产党第七届中央委员会第二次全体会议上的报告》，（一九四九年三月五日），《毛泽东选集》第四卷第一四二八页。在我国，虽然社会主义改造，在所有制方面说来，已经基本完成，革命时期的大规模的急风暴雨式的群众阶级斗争已经基本结束，但是，被推翻的地主买办阶级的残余还是存在，资产阶级还是存在，小资产阶级刚刚在改造。阶级斗争并没有结束。无产阶级和资产阶级之间的阶级斗争，各派政治力量之间的阶级斗争，无产阶级和资产阶级之间在意识形态方面的阶级斗争，还是长期的、曲折的，有时甚至是很激烈的。无产阶级要按照自己的世界观改造世界，资产阶级也要按照自己的世界观改造世界。在这一方面，社会主义和资本主义之间谁胜谁负的问题还没有真正解决。《关于正确处理人民内部矛盾的问题》（一九五七年二月二十七日），人民出版社第二六－－二七页教条主义和修正主义都是违反马克思主义的。马克思主义一定要向前发展，要随着实践的发展而发展，不能停滞不前。停止了，老是那么一套，它就没有生命了。但是，马克思主义的基本思想原则又是不能违背的，违背了就要犯错误。用形而上学的观点看待马克思主义的基本原则，这是教条主义。否定马列主义的基本原则，否定马克思主义的普遍真理，这就是修正主义。修正主义是一种资产阶级思想。修正主义者抹杀社会主义和资本主义的区别，抹杀无产阶级专政和资产阶级专政的区别。他们所主张的，在实际上并不是社会主义路线，而是资本主义路线。在现在的情况下，修正主义是比教条主义更有害的东西。我们现在思想路线上的一个重要任务，就是要展开对修正主义的批判。《在中国共产党全国宣传工作会议上的讲话》（一九五七年三月十二日），人民出版社第二○－－二一页。修正主义，或者右倾机会主义，是一种资产阶级思潮，它比教条主义有更大的危险性。修正主义者，右倾机会主义者，口头上也挂着马克思主义，他们也在那里攻击“教条主义”。但是他们所攻击的正是马克思主义的最根本的东西。他们反对或者歪曲唯物论和辩证法，反对或者企图削弱人民民主专政和共产党的领导，反对或者企图削弱是改造和社会主义建设。在我国社会主义革命取得基本胜利以后，社会上还有一部分人梦想恢复资本主义制度，他们要从各个方面向工人阶级进行斗争，包括思想方面的斗争。而在这个斗争中，修正主义者就是他们最好的助手。《关于正确处理人民内部矛盾的问题》（一九五七年二月二十七日）人民出版社第二九－－三○页。";
}


@end
