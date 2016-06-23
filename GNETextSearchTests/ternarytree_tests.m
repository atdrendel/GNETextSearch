//
//  ternarytree_tests.m
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ternarytree.h"
#import "GNETextSearchPrivate.h"


// ------------------------------------------------------------------------------------------


@interface GNETernaryTreeTests : XCTestCase
{
    tsearch_ternarytree_ptr _treePtr;
}

@end


// ------------------------------------------------------------------------------------------


@implementation GNETernaryTreeTests


// ------------------------------------------------------------------------------------------
#pragma mark - Set Up / Tear Down
// ------------------------------------------------------------------------------------------
- (void)setUp
{
    [super setUp];
    _treePtr = tsearch_ternarytree_init();
}

- (void)tearDown
{
    tsearch_ternarytree_free(_treePtr);
    _treePtr = NULL;
    [super tearDown];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Search Tests
// ------------------------------------------------------------------------------------------
- (void)testSearch_AddOneWord_CanFind
{
    NSString *word = @"Anthony";
    XCTAssertNoThrow([self insertWords:@[word] intoTree:_treePtr]);
    tsearch_countedset_ptr resultPtr = tsearch_ternarytree_copy_search_results(_treePtr, word.UTF8String);
    XCTAssertTrue(resultPtr != NULL);
    XCTAssertEqual((size_t)1, tsearch_countedset_get_count(resultPtr));
    XCTAssertEqual(1, tsearch_countedset_contains_int(resultPtr, (GNEInteger)word.hash));
    XCTAssertEqual(NULL, tsearch_ternarytree_copy_search_results(_treePtr, @"anthony".UTF8String));
    [self assertResultsInTree:_treePtr equalWords:@[word]];
    tsearch_countedset_free(resultPtr);
}


- (void)testSearch_AddTwoWords_CanFind
{
    NSArray *words = @[@"Ant", @"Awe"];
    XCTAssertNoThrow([self insertWords:words intoTree:_treePtr]);
    [self assertCanFindWords:words inTree:_treePtr];
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"ant".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"awe".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"An".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"Aw".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"A".UTF8String));
    [self assertResultsInTree:_treePtr equalWords:words];
}


- (void)testSearch_AddTwoWordsReversed_CanFind
{
    NSArray *words = @[@"Awe", @"Ant"];
    XCTAssertNoThrow([self insertWords:words intoTree:_treePtr]);
    [self assertCanFindWords:words inTree:_treePtr];
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"ant".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"awe".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"An".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"Aw".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"A".UTF8String));
    [self assertResultsInTree:_treePtr equalWords:@[@"Ant", @"Awe"]];
}


- (void)testSearch_AddThreeWords_CanFind
{
    NSArray *words = @[@"anthony", @"awesome", @"awful"];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);
    [self assertCanFindWords:words inTree:_treePtr];
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"Anthony".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"ant".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"awe".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"an".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"aw".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"a".UTF8String));
    [self assertResultsInTree:_treePtr equalWords:words];
}


- (void)testSearch_AddTenWords_CanFind
{
    NSString *wordsString = @"anthony is an awesome person or should we say 男人";
    NSArray *words = [wordsString componentsSeparatedByString:@" "];
    XCTAssertNoThrow([self insertWords:words intoTree:_treePtr]);
    [self assertCanFindWords:words inTree:_treePtr];
    [self assertResultsInTree:_treePtr equalWords:words];
}


- (void)testSearch_AddTwelveWords_CanFind
{
    NSArray *words = @[@"as", @"at", @"be", @"by", @"he", @"in",
                       @"is", @"it", @"of", @"on", @"or", @"to"];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);
    [self assertCanFindWords:words inTree:_treePtr];
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"ax".UTF8String));
    [self assertResultsInTree:_treePtr equalWords:words];
}


- (void)testSearch_AddEmoji_CanFind
{
    NSString *word = @"👌";
    XCTAssertNoThrow([self insertWords:@[word] intoTree:_treePtr]);
    tsearch_countedset_ptr resultsPtr = tsearch_ternarytree_copy_search_results(_treePtr, word.UTF8String);
    XCTAssertTrue(NULL != resultsPtr);
    [self assertResultsInTree:_treePtr equalWords:@[word]];
    tsearch_countedset_free(resultsPtr);
}


- (void)testSearch_LMN_CanFind
{
    NSArray *words = [self wordsBeginningWithLMN];
    XCTAssertNoThrow([self insertWords:words intoTree:_treePtr]);
    [self assertCanFindWords:[self randomizeWords:words] inTree:_treePtr];
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"magicia".UTF8String));
    [self assertResultsInTree:_treePtr equalWords:words];
}


- (void)testSearch_RandomizedLMN_CanFind
{
    NSArray *words = [self wordsBeginningWithLMN];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);
    [self assertCanFindWords:words inTree:_treePtr];
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"magicia".UTF8String));
    [self assertResultsInTree:_treePtr equalWords:words];
}


- (void)testSearch_A_CanFind
{
    NSArray *words = [self wordsBeginningWithA];
    XCTAssertNoThrow([self insertWords:words intoTree:_treePtr]);
    [self assertCanFindWords:[self randomizeWords:words] inTree:_treePtr];
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"atol".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"assa".UTF8String));
    [self assertResultsInTree:_treePtr equalWords:[self randomizeWords:words]];
}


- (void)testSearch_RandomizedA_CanFind
{
    NSArray *words = [self wordsBeginningWithA];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);
    [self assertCanFindWords:words inTree:_treePtr];
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"atol".UTF8String));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, @"assa".UTF8String));
    [self assertResultsInTree:_treePtr equalWords:words];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Prefix Search Tests
// ------------------------------------------------------------------------------------------
- (void)testPrefixSearch_AddTwelveWords_TwoResultsForA
{
    NSArray *words = @[@"as", @"at", @"be", @"by", @"he", @"in",
                       @"is", @"it", @"of", @"on", @"or", @"to"];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);
    [self assertResultsInTree:_treePtr matchingPrefix:@"a" equalWords:@[@"as", @"at"]];
}


- (void)testPrefixSearch_AddTwelveWords_ThreeResultsForI
{
    NSArray *words = @[@"as", @"at", @"be", @"by", @"he", @"in",
                       @"is", @"it", @"of", @"on", @"or", @"to"];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);
    [self assertResultsInTree:_treePtr matchingPrefix:@"i" equalWords:@[@"in", @"is", @"it"]];
}


- (void)testPrefixSearch_AddTwelveWordsInSpecificOrder_ThreeResultsForI
{
    NSArray *words = @[@"of", @"in", @"or", @"he", @"be", @"as",
                       @"at", @"it", @"on", @"is", @"by", @"to"];
    XCTAssertNoThrow([self insertWords:words intoTree:_treePtr]);
    [self assertResultsInTree:_treePtr matchingPrefix:@"i" equalWords:@[@"in", @"is", @"it"]];
}


- (void)testPrefixSearch_AddTwelveWords_NoResultsForC
{
    NSArray *words = @[@"as", @"at", @"be", @"by", @"he", @"in",
                       @"is", @"it", @"of", @"on", @"or", @"to"];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);

    tsearch_countedset_ptr resultsPtr = tsearch_ternarytree_copy_prefix_search_results(_treePtr, @"c".UTF8String);
    XCTAssertTrue(resultsPtr == NULL);
}


- (void)testPrefixSearch_AddSixWords_ThreeResultsForAw
{
    NSArray *words = @[@"anthony", @"awesome", @"awful", @"aw", @"Anthony", @"Aw"];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);
    [self assertResultsInTree:_treePtr matchingPrefix:@"aw" equalWords:@[@"awesome", @"awful", @"aw"]];
}


- (void)testPrefixSearch_AddSixWordsInOrderThatProducesDuplicates_ThreeResults
{
    NSArray *words = @[@"aw", @"anthony", @"awful", @"awesome", @"Anthony", @"Aw"];
    XCTAssertNoThrow([self insertWords:words intoTree:_treePtr]);
    [self assertResultsInTree:_treePtr matchingPrefix:@"aw" equalWords:@[@"awesome", @"awful", @"aw"]];
}


- (void)testPrefixSearch_LMN_TwoResultsForLaw
{
    NSString *prefix = @"law";

    NSArray *words = [self wordsBeginningWithLMN];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);

    NSArray *expectedWords = [self wordsInArray:randomizedWords withPrefix:prefix];
    [self assertResultsInTree:_treePtr matchingPrefix:prefix equalWords:expectedWords];
}


- (void)testPrefixSearch_LMN_EightResultsForMen
{
    NSString *prefix = @"men";

    NSArray *words = [self wordsBeginningWithLMN];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);

    NSArray *expectedWords = [self wordsInArray:randomizedWords withPrefix:prefix];
    [self assertResultsInTree:_treePtr matchingPrefix:prefix equalWords:expectedWords];
}


- (void)testPrefixSearch_LMN_ZeroResultsForOns
{
    NSString *prefix = @"ons";

    NSArray *words = [self wordsBeginningWithLMN];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);

    NSArray *expectedWords = [self wordsInArray:randomizedWords withPrefix:prefix];
    [self assertResultsInTree:_treePtr matchingPrefix:prefix equalWords:expectedWords];
}


- (void)testPrefixSearch_A_1404ResultsForA
{
    NSString *prefix = @"a";

    NSArray *words = [self wordsBeginningWithA];
    XCTAssertNoThrow([self insertWords:words intoTree:_treePtr]);

    NSArray *expectedWords = [self wordsInArray:words withPrefix:prefix];
    [self assertResultsInTree:_treePtr matchingPrefix:prefix equalWords:expectedWords];
}


- (void)testPrefixSearch_RandomizedA_1770ResultsForA
{
    NSString *prefix = @"a";

    NSArray *words = [self wordsBeginningWithA];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);

    NSArray *expectedWords = [self wordsInArray:randomizedWords withPrefix:prefix];
    [self assertResultsInTree:_treePtr matchingPrefix:prefix equalWords:expectedWords];
}


- (void)testPrefixSearch_A_31ResultsForAna
{
    NSString *prefix = @"ana";

    NSArray *words = [self wordsBeginningWithA];
    XCTAssertNoThrow([self insertWords:words intoTree:_treePtr]);

    NSArray *expectedWords = [self wordsInArray:words withPrefix:prefix];
    [self assertResultsInTree:_treePtr matchingPrefix:prefix equalWords:expectedWords];
}


- (void)testPrefixSearch_RandomizedA_31ResultsForAna
{
    NSString *prefix = @"ana";

    NSArray *words = [self wordsBeginningWithA];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);

    NSArray *expectedWords = [self wordsInArray:randomizedWords withPrefix:prefix];
    [self assertResultsInTree:_treePtr matchingPrefix:prefix equalWords:expectedWords];
}


- (void)testPrefixSearch_Emoji_OneResult
{
    NSArray *words = @[@"😊", @"😄", @"👹", @"✨", @"🇺🇸"];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);

    [self assertResultsInTree:_treePtr matchingPrefix:@"😄" equalWords:@[@"😄"]];
}


- (void)testPrefixSearch_Emoji_FourResultsForSharedEmojPrefix
{
    NSArray *words = @[@"😊", @"😄", @"👹", @"✨", @"🇺🇸"];
    NSArray *randomizedWords = [self randomizeWords:words];
    XCTAssertNoThrow([self insertWords:randomizedWords intoTree:_treePtr]);

    tsearch_countedset_ptr resultsPtr = tsearch_ternarytree_copy_prefix_search_results(_treePtr, "\xF0\x9F\0");
    XCTAssertTrue(resultsPtr != NULL);
    size_t count = tsearch_countedset_get_count(resultsPtr);
    XCTAssertEqual((size_t)4, count);

    GNEInteger *integers = NULL;
    count = 0;
    XCTAssertEqual(1, tsearch_countedset_copy_ints(resultsPtr, &integers, &count));
    XCTAssertTrue(integers != NULL);
    XCTAssertEqual((size_t)4, count);

    NSMutableArray *resultsArray = [NSMutableArray array];
    for (size_t i = 0; i < count; i++)
    {
        [resultsArray addObject:@(integers[i])];
    }

    NSArray *expectedResults = @[@(@"😄".hash), @(@"😊".hash), @(@"👹".hash), @(@"🇺🇸".hash)];

    NSSet *resultsSet = [NSSet setWithArray:resultsArray];
    NSSet *expectedResultsSet = [NSSet setWithArray:expectedResults];

    XCTAssertEqualObjects(expectedResultsSet, resultsSet);

    free(integers);
    tsearch_countedset_free(resultsPtr);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Remove Tests
// ------------------------------------------------------------------------------------------
- (void)testRemove_RemoveIDFromEmptyTree_Success
{
    XCTAssertEqual(0, [self resultsInTree:_treePtr].count);
    XCTAssertEqual(success, tsearch_ternarytree_remove(_treePtr, 1010));
}


- (void)testRemove_RemoveOnlyDocument_SuccessAndNoSearchResults
{
    GNEInteger documentID = 1010;
    NSString *text = @"word";
    [self insertWords:@[text] documentID:documentID intoTree:_treePtr];
    XCTAssertEqual(1, [self resultsInTree:_treePtr].count);
    [self assertCanFindWords:@[text] documentID:documentID inTree:_treePtr];

    XCTAssertEqual(success, tsearch_ternarytree_remove(_treePtr, documentID));
    XCTAssertEqual(0, [self resultsInTree:_treePtr].count);
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, text.UTF8String));
}


- (void)testRemove_RemoveOneDocumentForWordBelongingToTwoDocuments_SuccessAndCountOfOne
{
    GNEInteger firstID = 1234;
    GNEInteger secondID = 2345;
    NSArray *words = @[@"✈️"];
    [self insertWords:words documentID:firstID intoTree:_treePtr];
    [self insertWords:words documentID:secondID intoTree:_treePtr];

    tsearch_countedset_ptr resultsPtr = NULL;
    resultsPtr = tsearch_ternarytree_copy_search_results(_treePtr, [words.firstObject UTF8String]);
    XCTAssertTrue(resultsPtr != NULL);
    XCTAssertEqual(2, tsearch_countedset_get_count(resultsPtr));
    XCTAssertEqual(TRUE, tsearch_countedset_contains_int(resultsPtr, firstID));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(resultsPtr, firstID));
    XCTAssertEqual(TRUE, tsearch_countedset_contains_int(resultsPtr, secondID));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(resultsPtr, secondID));
    tsearch_countedset_free(resultsPtr);

    XCTAssertEqual(success, tsearch_ternarytree_remove(_treePtr, firstID));
    resultsPtr = tsearch_ternarytree_copy_search_results(_treePtr, [words.firstObject UTF8String]);
    XCTAssertTrue(resultsPtr != NULL);
    XCTAssertEqual(1, tsearch_countedset_get_count(resultsPtr));
    XCTAssertEqual(FALSE, tsearch_countedset_contains_int(resultsPtr, firstID));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(resultsPtr, firstID));
    XCTAssertEqual(TRUE, tsearch_countedset_contains_int(resultsPtr, secondID));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(resultsPtr, secondID));
    tsearch_countedset_free(resultsPtr);
}


- (void)testRemove_RemoveOneOfThreeDocuments_SuccessAndNoSearchResultsForRemoved
{
    GNEInteger firstID = 1234;
    GNEInteger secondID = 2345;
    GNEInteger thirdID = 3456;

    NSArray *firstWords = @[@"these", @"words", @"won't", @"be", @"removed"];
    NSArray *secondWords = @[@"isRemoved", @"isRemoved"];
    NSArray *thirdWords = @[@"these", @"words", @"also", @"won't", @"be", @"removed"];

    [self insertWords:firstWords documentID:firstID intoTree:_treePtr];
    [self assertCanFindWords:firstWords documentID:firstID inTree:_treePtr];
    [self insertWords:secondWords documentID:secondID intoTree:_treePtr];
    [self assertCanFindWords:secondWords documentID:secondID inTree:_treePtr];
    [self insertWords:thirdWords documentID:thirdID intoTree:_treePtr];
    [self assertCanFindWords:thirdWords documentID:thirdID inTree:_treePtr];

    XCTAssertEqual(success, tsearch_ternarytree_remove(_treePtr, secondID));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, [secondWords.firstObject UTF8String]));
    XCTAssertTrue(NULL == tsearch_ternarytree_copy_search_results(_treePtr, [secondWords.lastObject UTF8String]));

    [self assertCanFindWords:firstWords documentID:firstID inTree:_treePtr];
    [self assertCanFindWords:thirdWords documentID:thirdID inTree:_treePtr];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Performance
// ------------------------------------------------------------------------------------------
- (void)testInsertingBible__1_100
{
    NSDictionary *bible = [self bibleDictionary];

    [self measureBlock:^()
    {
        tsearch_ternarytree_ptr tree = tsearch_ternarytree_init();
        [bible enumerateKeysAndObjectsUsingBlock:^(NSNumber *documentID, NSArray *words, BOOL *stop) {
            for (NSString *word in words) {
                tsearch_ternarytree_insert(tree, word.UTF8String, documentID.longLongValue);
            }
        }];
        tsearch_ternarytree_free(tree);
    }];
}


- (void)testSearchBible_god__0_000
{
    [self insertBibleIntoTree:_treePtr];
    __block tsearch_countedset_ptr results = NULL;
    NSString *word = @"god";

    [self measureBlock:^()
    {
        results = tsearch_ternarytree_copy_search_results(_treePtr, word.UTF8String);
    }];
    XCTAssertEqual([self numberOfVersesInBibleContainingWord:word], tsearch_countedset_get_count(results));
}


- (void)testSearchBible_the__0_001
{
    [self insertBibleIntoTree:_treePtr];
    __block tsearch_countedset_ptr results = NULL;
    NSString *word = @"the";

    [self measureBlock:^()
    {
        results = tsearch_ternarytree_copy_search_results(_treePtr, word.UTF8String);
    }];
    XCTAssertEqual([self numberOfVersesInBibleContainingWord:word], tsearch_countedset_get_count(results));
}


- (void)testPrefixSearchBible_a__0_035
{
    [self insertBibleIntoTree:_treePtr];
    __block tsearch_countedset_ptr results = NULL;
    NSString *prefix = @"a";

    [self measureBlock:^()
    {
        results = tsearch_ternarytree_copy_prefix_search_results(_treePtr, prefix.UTF8String);
    }];

    XCTAssertEqual([self numberOfVersesInBibleContainingPrefix:prefix], tsearch_countedset_get_count(results));
}


// ------------------------------------------------------------------------------------------
#pragma mark - Helpers
// ------------------------------------------------------------------------------------------
- (void)insertWords:(NSArray *)words intoTree:(tsearch_ternarytree_ptr)treePtr
{
    if (treePtr == NULL)
    {
        return;
    }

    for (NSString *word in words)
    {
        XCTAssertTrue(NULL != tsearch_ternarytree_insert(treePtr, word.UTF8String, word.hash));
    }
}


- (void)insertWords:(NSArray *)words
         documentID:(GNEInteger)documentID
           intoTree:(tsearch_ternarytree_ptr)treePtr
{
    if (treePtr == NULL)
    {
        return;
    }

    for (NSString *word in words)
    {
        XCTAssertTrue(NULL != tsearch_ternarytree_insert(treePtr, word.UTF8String, documentID));
    }
}


- (void)assertCanFindWords:(NSArray *)words inTree:(tsearch_ternarytree_ptr)ptr
{
    for (NSString *word in words)
    {
        tsearch_countedset_ptr resultsPtr = tsearch_ternarytree_copy_search_results(ptr, word.UTF8String);
        size_t count = tsearch_countedset_get_count(resultsPtr);
        XCTAssertTrue(count > 0);
        XCTAssertTrue(tsearch_countedset_contains_int(resultsPtr, (GNEInteger)word.hash));
        tsearch_countedset_free(resultsPtr);
    }
}


- (void)assertCanFindWords:(NSArray *)words
                documentID:(GNEInteger)documentID
                    inTree:(tsearch_ternarytree_ptr)ptr
{
    for (NSString *word in words)
    {
        tsearch_countedset_ptr resultsPtr = tsearch_ternarytree_copy_search_results(ptr, word.UTF8String);
        size_t count = tsearch_countedset_get_count(resultsPtr);
        XCTAssertTrue(count > 0);
        XCTAssertTrue(tsearch_countedset_contains_int(resultsPtr, documentID));
        tsearch_countedset_free(resultsPtr);
    }
}


- (void)assertResultsInTree:(tsearch_ternarytree_ptr)ptr equalWords:(NSArray *)words
{
    NSArray *results = [self resultsInTree:ptr];
    XCTAssertEqual(results.count, words.count);
    XCTAssertEqualObjects([NSSet setWithArray:words], [NSSet setWithArray:results]);
}


- (void)assertResultsInTree:(tsearch_ternarytree_ptr)ptr
             matchingPrefix:(NSString *)prefix
                 equalWords:(NSArray *)words
{
    tsearch_countedset_ptr resultsPtr = tsearch_ternarytree_copy_prefix_search_results(ptr, prefix.UTF8String);

    XCTAssert((words.count == 0 && resultsPtr == NULL) ||
              (words.count == tsearch_countedset_get_count(resultsPtr)));

    for (NSString *word in words)
    {
        XCTAssertEqual(1, tsearch_countedset_contains_int(resultsPtr, (GNEInteger)word.hash));
    }
    tsearch_countedset_free(resultsPtr);
}


- (NSArray *)resultsInTree:(tsearch_ternarytree_ptr)ptr
{
    NSString *resultsStr = @"";

    if (ptr == NULL)
    {
        return @[resultsStr];
    }

    char *results = NULL;
    size_t length = 0;

    if (tsearch_ternarytree_copy_contents(ptr, &results, &length) == 1)
    {
        NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        resultsStr = [[NSString stringWithUTF8String:results] stringByTrimmingCharactersInSet:characterSet];
    }

    free(results);

    return (resultsStr.length > 0) ? [resultsStr componentsSeparatedByString:@"\n"] : @[];
}


- (NSArray *)randomizeWords:(NSArray *)words
{
    NSMutableArray *mutableCopy = [NSMutableArray arrayWithArray:words];
    NSMutableArray *randomized = [NSMutableArray array];
    while (mutableCopy.count > 0)
    {
        NSUInteger count = mutableCopy.count;
        NSUInteger randomIndex = (NSUInteger)arc4random_uniform((u_int32_t)count);
        [randomized addObject:mutableCopy[randomIndex]];
        [mutableCopy removeObjectAtIndex:randomIndex];
    }

    return [randomized copy];
}


- (NSArray *)wordsInArray:(NSArray *)words withPrefix:(NSString *)prefix
{
    NSMutableArray *wordsWithPrefix = [NSMutableArray array];
    for (NSString *word in words)
    {
        if ([word hasPrefix:prefix])
        {
            [wordsWithPrefix addObject:word];
        }
    }

    return [wordsWithPrefix copy];
}


- (void)insertBibleIntoTree:(tsearch_ternarytree_ptr)treePtr
{
    NSDictionary *bible = [self bibleDictionary];
    [bible enumerateKeysAndObjectsUsingBlock:^(NSNumber *documentID, NSArray *words, BOOL *stop) {
        for (NSString *word in words) {
            tsearch_ternarytree_insert(_treePtr, word.UTF8String, documentID.longLongValue);
        }
    }];
}


- (NSInteger)numberOfVersesInBibleContainingWord:(NSString *)word
{
    __block NSInteger count = 0;
    NSDictionary *bible = [self bibleDictionary];
    [bible enumerateKeysAndObjectsUsingBlock:^(id verse, NSArray<NSString *> *words, BOOL *stop) {
        NSInteger wordCount = [words indexesOfObjectsPassingTest:^BOOL(NSString *obj, NSUInteger idx, BOOL *stop)
        {
            return [obj isEqualToString:word];
        }].count;
        count += (wordCount > 0) ? 1 : 0;
    }];

    return count;
}


- (NSInteger)numberOfVersesInBibleContainingPrefix:(NSString *)prefix
{
    __block NSInteger count = 0;
    NSDictionary *bible = [self bibleDictionary];
    [bible enumerateKeysAndObjectsUsingBlock:^(id verse, NSArray<NSString *> *words, BOOL *stop) {
        NSInteger wordCount = [words indexesOfObjectsPassingTest:^BOOL(NSString *obj, NSUInteger idx, BOOL *stop)
        {
            return [obj hasPrefix:prefix];
        }].count;
        count += (wordCount > 0) ? 1 : 0;
    }];
    
    return count;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Word Lists
// ------------------------------------------------------------------------------------------
- (NSArray *)wordsBeginningWithLMN
{
    NSString *lmn = @"lawmaker lawsuits laxative laxities layaways layering layettes layovers laziness leaching"
    @"leadings leadoffs leafiest leaflets leaguers leaguing leakages leakiest leanings leapfrog learners learning"
    @"leasable leashing leathers leathery leavened leavings lebanese lecithin lecterns lectured lecturer lectures"
    @"leeching leeriest leewards leftists leftmost leftover legacies legalism legalist legality legalize legatees"
    @"legation leggiest leggings leghorns leisured leisures lemmings lemonade lemonier lengthen lenience leniency"
    @"leninist lenities lenitive leopards leotards lesbians lessened letdowns lethargy lettered leukemia levelers"
    @"leveling leverage levering levitate levities lewdness lexicons liaisons libation libelers libeling libelous"
    @"liberals liberate liberian libretto licensed licensee licenser licenses lickings licorice lifeboat lifeless"
    @"lifelike lifeline lifelong lifetime lifework liftoffs ligament ligature lightens lighters lightest lighting"
    @"ligneous lignites ligroins likelier likeness likening likewise limbered limeades limerick limiting limonite"
    @"linchpin lineages linearly linefeed linesman linesmen lingered lingerer lingerie linguini linguist liniment"
    @"linkages linkings linnaean linoleum linotype linseeds lionized lionizes lipstick liqueurs listened listener"
    @"listings listless litanies literacy literary literate literati lithiums litigant litigate litmuses littered"
    @"littlest littoral livelier livelong livening liveried liveries loamiest loathing lobbying lobbyist lobelias"
    @"loblolly lobotomy lobsters locality localize locating location locative locators lockjaws lockouts locoweed"
    @"locution lodestar lodgings lodgment loftiest logbooks logicals logician logistic logotype loitered loiterer"
    @"lollipop londoner lonelier lonesome longboat longbows longhair longhand longhorn longings longleaf longlegs"
    @"lookouts looniest loophole loosened lopsided lordlier lordship lothario loudness lounging lousiest louvered"
    @"lovebird loveless lovelier lovelies lovelorn lovesick lovingly lowbrows lowdowns lowering lowlands lowliest"
    @"loyalist lozenged lozenges lucidity luckiest luckless lukewarm lumbagos lumbered luminary luminous lummoxes"
    @"lumpiest lunacies lunatics luncheon lunching lunettes lungfish lurching luscious lustiest lustrous lutetium"
    @"lutheran luxuries lymphoid lynching lyrebird lyricism lyricist lysergic macaques macaroni macaroon macerate"
    @"machetes machined machines machismo mackerel mackinaw maddened madhouse madonnas madrases madrigal madwoman"
    @"madwomen maestros magazine magcards magentas magician magnates magnesia magnetic magnetos magnolia maharani"
    @"mahatmas mahjongs mahogany maidenly mailbags mailgram mailings mainland mainline mainmast mainsail mainstay"
    @"maintain maintops majestic majolica majoring majority maladies malagasy malaises malamute malarial malarias"
    @"malarkey malaysia maldives maleness maligned malinger mallards malmseys maltases maltoses maltreat mammoths"
    @"manacled manacles managers managing manatees mandamus mandarin mandated mandates mandible mandolin mandrake"
    @"mandrels mandrill maneuver manfully mangiest mangling mangrove manholes manhoods manhunts maniacal manicure"
    @"manifest manifold manikins maniples manliest mannered mannerly manorial manpower mansards mansions mantilla"
    @"mantises mantissa mantling manually manumits marabous marathon marauded marauder marbling marchers marching"
    @"marginal margined marigold marimbas marinade marinate mariners mariposa maritime marjoram markdown markedly"
    @"marketed marketer markings marksman marksmen marlines marmoset marooned marquees marquise marriage marrying"
    @"marshals marshier martians martinet martinis martyred marveled marxists maryland marzipan massacre massaged"
    @"massages masseurs masseuse mastered masterly masthead mastiffs mastitis mastodon mastoids matadors matchbox"
    @"matching material materiel maternal matinees matrices matrixes matronly mattered mattings mattocks mattress"
    @"maturate maturing maturity maunders maverick maxillae maxillar maximize maximums mayflies mazurkas mealtime"
    @"meanders meanings meanness meantime measlier measured measurer measures meatball meatiest mechanic meddlers"
    @"meddling mediated mediates mediator medicaid medicare medicate medicine medieval mediocre meditate medullar"
    @"medullas meetings megabits megabyte megalith megatons megawatt melamine melanges melanins melanoma meldings"
    @"mellitus mellowed mellower melodeon melodies meltable meltdown membrane mementos memorial memoriam memories"
    @"memorize menacing menhaden meninges meniscal meniscus mentally menthols mentions mephitic mephitis merchant"
    @"merciful mercuric meridian meringue meriting mermaids merriest meshwork mesoderm mesozoic mesquite messages"
    @"messiest metallic metaphor metazoan meteoric metering methanes methanol methinks metonyms metonymy metrical"
    @"mexicans mezuzahs michigan microbes middling midlands midnight midpoint midriffs midterms midweeks midwives"
    @"midyears mightier mightily migraine migrants migrated migrates milanese mildewed mildness mileages milepost"
    @"militant military militate militias milkiest milkmaid milksops milkweed milldams milliard milliner millions"
    @"millrace mimicked mimicker minarets minatory mindless minerals mingling minicabs minidisk minimize minimums"
    @"minister ministry minority minotaur minstrel mintages minuends minutely minutiae miracles mirrored mirthful"
    @"misapply miscalls miscarry miscasts mischief miscible miscount miscuing misdeals misdealt misdeeds misdoing"
    @"miseries misfired misfires misguide misheard mishears mishmash misjudge misleads mismatch misnamed misnames"
    @"misnomer misogamy misogyny misplace misplays misprint misquote misreads misruled misrules misshape missiles"
    @"missions missives missouri misspell misspend misspent misstate missteps mistaken mistakes mistiest mistrals"
    @"mistreat mistress mistrial mistrust misusing mitering mitigate mitzvahs mixtures mnemonic mobility mobilize"
    @"mobsters moccasin modality modeling moderate moderato modestly modicums modified modifier modifies modulate"
    @"mohammed moieties moistens moistest moisture molasses moldable moldered moldiest moldings molecule molehill"
    @"moleskin molested mollusks momentum monarchs monarchy monastic monaural monazite monetary moneybag mongered"
    @"mongolia mongoose mongrels monikers monistic monition monitors monitory monkeyed monocles monodies monodist"
    @"monogamy monogram monolith monomers monomial monopoly monorail monotone monotony monotype monoxide monsoons"
    @"monsters montages monument moochers mooching moodiest moonbeam mooncalf mooniest moorages moorings moraines"
    @"moralist morality moralize morasses mordancy mordents moreover moribund mornings moroccan morosely morpheme"
    @"morpheus morphine mortally mortared mortgage mortised mortises mortuary moseying mosquito mossback mossiest"
    @"mothball mothered motherly motility motioned motivate motorcar motoring motorist motorize motorman motormen"
    @"mottling mounding mountain mounting mourners mournful mourning mousiest mouthful mouthing movement movingly"
    @"mucilage muckrake muddiest muddling muddying mudguard muezzins mufflers muffling muggiest muggings mulattos"
    @"mulberry mulching mulcting muleteer mulleins mulligan mullions multiple multiply mumbling muminous munching"
    @"muralist murcatel murdered murderer murkiest murmured murrains muscling muscular mushiest mushroom musicale"
    @"musicals musician musketry muskrats mustache mustangs mustards mustered mustiest mutating mutation mutative"
    @"muteness mutilate mutineer mutinied mutinies mutinous muttered mutually muzzling mycelium mycology myrmidon"
    @"mystical mystique mythical nacelles nacreous naivetes nameless namesake namibian nankeens naperies napoleon"
    @"narcoses narcosis narcotic narrated narrates narrator narrowed narrower narrowly narwhals nasality nascence"
    @"nastiest national nativity nattiest naturals nauseate nauseous nautical nautilus navigate nazarene nearness"
    @"neatness nebraska nebulous necklace neckline neckties neckwear neediest needless needling negating negation"
    @"negative neglects negligee neighbor nektonic nematode nembutal neomycin neonatal neonates neophyte neoplasm"
    @"neoprene nepalese nepenthe nephrite nepotism nerviest nervosas nestling netsukes nettling networks neuritis"
    @"neuroses neurosis neurotic neutered neutrals neutrino neutrons newborns newcomer newlywed newsboys newscast"
    @"newsiest newsreel nibbling niceties nickname nicotine niftiest nigerian niggling nightcap nihilism nihilist"
    @"nimblest ninepins nineteen nineties nippiest nirvanas nitrated nitrates nitrides nitrites nitrogen nobelium"
    @"nobility nobleman noblemen noblesse nobodies nocturne noisiest nominate nominees nomogram nonagons nonesuch"
    @"nonjuror nonmetal nonsense nonunion nonwhite noodling noondays noontide noontime normalcy normally northern"
    @"nosegays nosiness nostrils nostrums notables notaries notarize notation notching notebook nothings noticing"
    @"notified notifies notional nouveaux novelist novellas november novocain nowadays nuclease nucleate nucleoli"
    @"nucleons nudities nugatory nuisance numbered numbness numerals numerate numerous numskull nuptials nursling"
    @"nurtured nurtures nuthatch nutmeats nutrient nutshell";

    return [lmn componentsSeparatedByString:@" "];
}


- (NSArray *)wordsBeginningWithA
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"words-beginning-with-A" ofType:@"txt"];
    NSParameterAssert(path);
    NSError *error = nil;
    NSString *wordsString = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    NSAssert2(error == nil, @"Could not open %@: %@", path, error);

    return [wordsString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}


- (NSDictionary *)bibleDictionary
{
    static NSDictionary *dictionary = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"bible" ofType:@"archive"];
        NSParameterAssert(path);
        dictionary = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    });

    return dictionary;
}


@end
