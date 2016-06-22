//
//  GNEIntegerCountedSetTests.m
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/14/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "countedset.h"
#import "GNETextSearchPrivate.h"


// ------------------------------------------------------------------------------------------


typedef struct _tsearch_countedset_node
{
    GNEInteger integer;
    size_t count;
    int balance;
    size_t left;
    size_t right;
} _tsearch_countedset_node;


typedef struct tsearch_countedset
{
    _tsearch_countedset_node *nodes;
    size_t count; // The number of nodes whose count > 0.
    size_t nodesCapacity;
    size_t insertIndex;
} tsearch_countedset;


// ------------------------------------------------------------------------------------------


@interface GNEIntegerCountedSetTests : XCTestCase
{
    tsearch_countedset_ptr _countedSet;
}

@end


// ------------------------------------------------------------------------------------------


@implementation GNEIntegerCountedSetTests


// ------------------------------------------------------------------------------------------
#pragma mark - Set Up / Tear Down
// ------------------------------------------------------------------------------------------
- (void)setUp
{
    [super setUp];
    _countedSet = tsearch_countedset_init();
}


- (void)tearDown {
    tsearch_countedset_free(_countedSet);
    _countedSet = NULL;
    [super tearDown];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Initialization
// ------------------------------------------------------------------------------------------
- (void)testInitialization_Standard_NotNullAndZeroCount
{
    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(0, _countedSet->insertIndex);
    XCTAssertEqual(5 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(0, _countedSet->count);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Copy
// ------------------------------------------------------------------------------------------
- (void)testCopy_NullPointer_Null
{
    XCTAssertTrue(NULL == tsearch_countedset_copy(NULL));
}


- (void)testCopy_EmptySet_EquivalentSet
{
    tsearch_countedset_ptr copyPtr = tsearch_countedset_copy(_countedSet);
    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(copyPtr != NULL);
    XCTAssertNotEqual(_countedSet, copyPtr);
    XCTAssertEqual(_countedSet->count, copyPtr->count);
    XCTAssertEqual(_countedSet->nodesCapacity, copyPtr->nodesCapacity);
    XCTAssertEqual(_countedSet->insertIndex, copyPtr->insertIndex);
    XCTAssertEqual(0, memcmp(_countedSet->nodes, copyPtr->nodes, _countedSet->nodesCapacity));
}


- (void)testCopy_FiveIntegers_EquivalentSet
{
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 12343232));
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 3223));
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 3242351245));
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 12312));
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 0));
    XCTAssertEqual(5, _countedSet->count);

    tsearch_countedset_ptr copyPtr = tsearch_countedset_copy(_countedSet);
    XCTAssertTrue(_countedSet != NULL);
    XCTAssertEqual(5, _countedSet->count);
    XCTAssertTrue(copyPtr != NULL);
    XCTAssertNotEqual(_countedSet, copyPtr);
    XCTAssertEqual(_countedSet->count, copyPtr->count);
    XCTAssertEqual(_countedSet->nodesCapacity, copyPtr->nodesCapacity);
    XCTAssertEqual(_countedSet->insertIndex, copyPtr->insertIndex);
    XCTAssertEqual(0, memcmp(_countedSet->nodes, copyPtr->nodes, _countedSet->nodesCapacity));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 12343232));
    XCTAssertEqual(true, tsearch_countedset_contains_int(copyPtr, 12343232));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 3223));
    XCTAssertEqual(true, tsearch_countedset_contains_int(copyPtr, 3223));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 3242351245));
    XCTAssertEqual(true, tsearch_countedset_contains_int(copyPtr, 3242351245));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 12312));
    XCTAssertEqual(true, tsearch_countedset_contains_int(copyPtr, 12312));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 0));
    XCTAssertEqual(true, tsearch_countedset_contains_int(copyPtr, 0));
}


// ------------------------------------------------------------------------------------------
#pragma mark - Count
// ------------------------------------------------------------------------------------------
- (void)testCount_NullPointer_Zero
{
    XCTAssertEqual(0, tsearch_countedset_get_count(NULL));
}


- (void)testCount_EmptySet_Zero
{
    XCTAssertEqual(0, _countedSet->count);
    XCTAssertEqual(0, tsearch_countedset_get_count(_countedSet));
}


- (void)testCount_OneInteger_One
{
    XCTAssertEqual(1, tsearch_countedset_add_int(_countedSet, 12343232));
    XCTAssertEqual(1, _countedSet->count);
    XCTAssertEqual(1, tsearch_countedset_get_count(_countedSet));
}


- (void)testCount_OneIntegerTwoTimes_One
{
    XCTAssertEqual(1, tsearch_countedset_add_int(_countedSet, 12343232));
    XCTAssertEqual(1, tsearch_countedset_add_int(_countedSet, 12343232));
    XCTAssertEqual(1, _countedSet->count);
    XCTAssertEqual(1, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 12343232));
}


- (void)testCount_FiveIntegersMinusOne_Four
{
    XCTAssertEqual(1, tsearch_countedset_add_int(_countedSet, 12343232));
    XCTAssertEqual(1, tsearch_countedset_add_int(_countedSet, 3223));
    XCTAssertEqual(1, tsearch_countedset_add_int(_countedSet, 3242351245));
    XCTAssertEqual(1, tsearch_countedset_add_int(_countedSet, 12312));
    XCTAssertEqual(1, tsearch_countedset_add_int(_countedSet, 0));
    XCTAssertEqual(5, _countedSet->count);
    XCTAssertEqual(5, tsearch_countedset_get_count(_countedSet));

    XCTAssertEqual(1, tsearch_countedset_remove_int(_countedSet, 0));
    XCTAssertEqual(4, _countedSet->count);
    XCTAssertEqual(4, tsearch_countedset_get_count(_countedSet));
}


- (void)testCount_RandomIntegers_EqualsCountOfNSSet
{
    NSArray *numbers = [self p_tenThousandRandomIntegers_1];
    for (NSNumber *number in numbers)
    {
        XCTAssertEqual(1, tsearch_countedset_add_int(_countedSet, (GNEInteger)number.integerValue));
    }
    NSSet *set = [NSSet setWithArray:numbers];
    XCTAssertEqual((size_t)set.count, _countedSet->count);
    XCTAssertEqual((size_t)set.count, tsearch_countedset_get_count(_countedSet));
}


// ------------------------------------------------------------------------------------------
#pragma mark - Copy Integers
// ------------------------------------------------------------------------------------------
- (void)testCopyIntegers_FourUniqueIntegers_FourResultsInCorrectOrder
{
    size_t count = 10;
    GNEInteger integers[] = {8, 4, 7, 4, 4, 8, 3, 4, 7, 8};

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];
    XCTAssertEqual(4, _countedSet->count);

    GNEInteger *results = NULL;
    size_t resultsCount = 0;
    XCTAssertEqual(1, tsearch_countedset_copy_ints(_countedSet, &results, &resultsCount));
    XCTAssertEqual(resultsCount, 4);
    XCTAssertEqual(4, results[0]);
    XCTAssertEqual(8, results[1]);
    XCTAssertEqual(7, results[2]);
    XCTAssertEqual(3, results[3]);

    free(results);
}


- (void)testCopyIntegers_FourIntegersMinusTwo_TwoResultsInCorrectOrder
{
    size_t count = 10;
    GNEInteger integers[] = {8, 4, 7, 4, 4, 8, 3, 4, 7, 8};

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];
    XCTAssertEqual(4, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(success, tsearch_countedset_remove_int(_countedSet, 4));
    XCTAssertEqual(success, tsearch_countedset_remove_int(_countedSet, 7));
    XCTAssertEqual(2, tsearch_countedset_get_count(_countedSet));

    GNEInteger *results = NULL;
    size_t resultsCount = 0;
    XCTAssertEqual(1, tsearch_countedset_copy_ints(_countedSet, &results, &resultsCount));
    XCTAssertEqual(resultsCount, 2);
    XCTAssertEqual(8, results[0]);
    XCTAssertEqual(3, results[1]);

    free(results);
}


- (void)testCopyIntegers_OneThousandRandomIntegers_ResultsInCorrectOrder
{
    NSArray *numbers = [self p_randomNumberArrayWithCount:1000];

    [self p_addNumbers:numbers toCountedSet:_countedSet];
    NSCountedSet *countedSet = [self p_countedSetWithNumbers:numbers];

    XCTAssertEqual(countedSet.count, tsearch_countedset_get_count(_countedSet));

    NSMutableDictionary *countToResultsMap = [NSMutableDictionary dictionary];
    for (NSNumber *number in countedSet)
    {
        NSUInteger count = [countedSet countForObject:number];
        NSMutableArray *results = countToResultsMap[@(count)];
        if (results == nil)
        {
            results = [NSMutableArray array];
            countToResultsMap[@(count)] = results;
        }
        [results addObject:number];
    }

    GNEInteger *results = NULL;
    size_t resultsCount = 0;
    XCTAssertEqual(1, tsearch_countedset_copy_ints(_countedSet, &results, &resultsCount));
    XCTAssertTrue(results != NULL);
    XCTAssertEqual((size_t)countedSet.count, resultsCount);

    NSArray *descendingCounts = [[[[countToResultsMap allKeys]
                                    sortedArrayUsingSelector:@selector(compare:)]
                                        reverseObjectEnumerator] allObjects];

    // The order of results is guaranteed to be in descending order according to
    // the count of each integer. However, if multiple integers have the same count
    // then the order within that group is undefined. So, for each count group
    // we iterate over the next results and make sure they are in the group.
    NSRange range = NSMakeRange(0, 0);
    for (NSNumber *count in descendingCounts)
    {
        NSSet *resultsForCount = [NSSet setWithArray:countToResultsMap[count]];
        range.length = resultsForCount.count;
        for (size_t i = (size_t)range.location; i < (size_t)range.length; i++)
        {
            XCTAssertTrue([resultsForCount containsObject:@(results[i])]);
        }
        range.location += range.length;
    }

    free(results);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Add/Contains/Count Integers
// ------------------------------------------------------------------------------------------
- (void)testAddIntegers_ZeroAndOne_CorrectValuesAndCount
{
    size_t count = 2;
    GNEInteger integers[] = {0, 1};

    [self p_addIntegers:integers count:2 toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(5 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(count, _countedSet->count);

    [self p_assertCountedSet:_countedSet containsIntegers:integers count:count];

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));
}


- (void)testAddIntegers_ZeroOneAndTwo_CorrectValuesAndCount
{
    size_t count = 3;
    GNEInteger integers[] = {0, 1, 2};

    [self p_addIntegers:integers count:3 toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(5 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(count, _countedSet->count);

    [self p_assertCountedSet:_countedSet containsIntegers:integers count:count];

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));
}


- (void)testAddIntegers_ZeroOneTwoThree_CorrectValuesAndCount
{
    size_t count = 4;
    GNEInteger integers[] = {0, 1, 2, 3};

    [self p_addIntegers:integers count:4 toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(10 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(count, _countedSet->count);

    [self p_assertCountedSet:_countedSet containsIntegers:integers count:count];

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));
}


- (void)testAddIntegers_AddTenFourTimes_NoDuplicatesCorrectValuesAndCount
{
    size_t count = 1;
    GNEInteger integers[] = {10, 10, 10, 10};

    [self p_addIntegers:integers count:4 toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(5 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(count, _countedSet->count);

    [self p_assertCountedSet:_countedSet containsIntegers:integers count:count];
}


- (void)testAddIntegers_LeftLeftRotation_CorrectRotation
{
    GNEInteger integers[] = {8, 7, 2};
    size_t count = 3;

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    _tsearch_countedset_node *nodes = _countedSet->nodes;

    XCTAssertEqual(7, nodes[0].integer);
    XCTAssertEqual(2, nodes[0].left);
    XCTAssertEqual(1, nodes[0].right);

    XCTAssertEqual(8, nodes[1].integer);
    XCTAssertEqual(SIZE_MAX, nodes[1].left);
    XCTAssertEqual(SIZE_MAX, nodes[1].right);

    XCTAssertEqual(2, nodes[2].integer);
    XCTAssertEqual(SIZE_MAX, nodes[2].left);
    XCTAssertEqual(SIZE_MAX, nodes[2].right);

    XCTAssertEqual(3, tsearch_countedset_get_count(_countedSet));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 8));
}


- (void)testAddIntegers_LeftRightRotation_CorrectRotation
{
    GNEInteger integers[] = {8, 2, 7};
    size_t count = 3;

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    _tsearch_countedset_node *nodes = _countedSet->nodes;

    XCTAssertEqual(7, nodes[0].integer);
    XCTAssertEqual(1, nodes[0].left);
    XCTAssertEqual(2, nodes[0].right);

    XCTAssertEqual(2, nodes[1].integer);
    XCTAssertEqual(SIZE_MAX, nodes[1].left);
    XCTAssertEqual(SIZE_MAX, nodes[1].right);

    XCTAssertEqual(8, nodes[2].integer);
    XCTAssertEqual(SIZE_MAX, nodes[2].left);
    XCTAssertEqual(SIZE_MAX, nodes[2].right);

    XCTAssertEqual(3, tsearch_countedset_get_count(_countedSet));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 8));
}


- (void)testAddIntegers_RightLeftRotation_CorrectRotation
{
    GNEInteger integers[] = {2, 8, 7};
    size_t count = 3;

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    _tsearch_countedset_node *nodes = _countedSet->nodes;

    XCTAssertEqual(7, nodes[0].integer);
    XCTAssertEqual(2, nodes[0].left);
    XCTAssertEqual(1, nodes[0].right);

    XCTAssertEqual(8, nodes[1].integer);
    XCTAssertEqual(SIZE_MAX, nodes[1].left);
    XCTAssertEqual(SIZE_MAX, nodes[1].right);

    XCTAssertEqual(2, nodes[2].integer);
    XCTAssertEqual(SIZE_MAX, nodes[2].left);
    XCTAssertEqual(SIZE_MAX, nodes[2].right);

    XCTAssertEqual(3, tsearch_countedset_get_count(_countedSet));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 8));
}


- (void)testAddIntegers_RightRightRotation_CorrectRotation
{
    GNEInteger integers[] = {2, 7, 8};
    size_t count = 3;

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    _tsearch_countedset_node *nodes = _countedSet->nodes;

    XCTAssertEqual(7, nodes[0].integer);
    XCTAssertEqual(1, nodes[0].left);
    XCTAssertEqual(2, nodes[0].right);

    XCTAssertEqual(2, nodes[1].integer);
    XCTAssertEqual(SIZE_MAX, nodes[1].left);
    XCTAssertEqual(SIZE_MAX, nodes[1].right);

    XCTAssertEqual(8, nodes[2].integer);
    XCTAssertEqual(SIZE_MAX, nodes[2].left);
    XCTAssertEqual(SIZE_MAX, nodes[2].right);

    XCTAssertEqual(3, tsearch_countedset_get_count(_countedSet));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 8));
}


- (void)testAddIntegers_TwelveIntegersNeedingThreeRotations_CorrectCounts
{
    GNEInteger integers[] = {7, 2, 8, 1, 3, 6, 5, 4, 9, 11, 12, 13};
    size_t count = 12;

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    XCTAssertEqual(count, tsearch_countedset_get_count(_countedSet));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 8));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 1));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 3));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 3));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 6));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 5));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 5));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 4));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 9));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 9));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 11));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 11));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 12));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 12));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 13));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 13));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 10));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 10));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 0));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 0));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 2342342));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 2342342));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, -1));
}


- (void)testAddIntegers_AddTenNumbers_NoDuplicatesAndCorrectCounts
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(10 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(6, _countedSet->count);
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 8));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 4));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 3));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 0));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 3));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 5));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 9));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 10));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));
}


- (void)testAddIntegers_AddTenThousandIntegersFourTimes_NoDuplicatesCorrectValuesAndCounts
{
    size_t count = 10000;
    GNEInteger *integers = calloc(4 * count, sizeof(GNEInteger));
    size_t *counts = calloc(count, sizeof(size_t));
    for (size_t i = 0; i < (4 * count); i++)
    {
        integers[i] = i % count;
        if (i < count) { counts[i] = 4; }
    }

    [self p_addIntegers:integers count:(4 * count) toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(10240 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(count, _countedSet->count);

    [self p_assertCountedSet:_countedSet containsIntegers:integers count:count];

    free(integers);
    free(counts);
}


- (void)testAddIntegers_AddTenHundredThousandRandomIntegers_EqualToNSCountedSet
{
    size_t count = 10000;
    NSArray *numbers = [self p_randomNumberArrayWithCount:count];
    [self p_addNumbers:numbers toCountedSet:_countedSet];
    NSCountedSet *nsCountedSet = [self p_countedSetWithNumbers:numbers];
    [self p_assertGNECountedSet:_countedSet isEqualToNSCountedSet:nsCountedSet];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Remove Integer
// ------------------------------------------------------------------------------------------
- (void)testRemove_EmptySetRemoveOne_Success
{
    XCTAssertEqual(0, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(success, tsearch_countedset_remove_int(_countedSet, 1));
    XCTAssertEqual(0, tsearch_countedset_get_count(_countedSet));
}


- (void)testRemove_RemoveOnlyInteger_ZeroCount
{
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 1));
    XCTAssertEqual(1, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(success, tsearch_countedset_remove_int(_countedSet, 1));
    XCTAssertEqual(0, tsearch_countedset_get_count(_countedSet));
}


- (void)testRemove_OneIntegerTwiceRemove_ZeroCount
{
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 1));
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 1));
    XCTAssertEqual(1, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 1));
    XCTAssertEqual(success, tsearch_countedset_remove_int(_countedSet, 1));
    XCTAssertEqual(0, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 1));
}


- (void)testRemove_ThreeIntegersRemoveFirst_TwoRemaining
{
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 1));
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 2));
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 3));
    XCTAssertEqual(3, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(success, tsearch_countedset_remove_int(_countedSet, 1));
    XCTAssertEqual(2, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 1));
}


- (void)testRemove_ThreeIntegersRemoveAll_ZeroCounts
{
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 1));
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 2));
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 3));
    XCTAssertEqual(3, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(success, tsearch_countedset_remove_all_ints(_countedSet));
    XCTAssertEqual(0, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 1));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 3));
}


- (void)testRemove_ThreeIntegersRemoveSecondAndThenRemoveAll_ZeroCounts
{
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 1));
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 2));
    XCTAssertEqual(success, tsearch_countedset_add_int(_countedSet, 3));
    XCTAssertEqual(3, tsearch_countedset_get_count(_countedSet));

    XCTAssertEqual(success, tsearch_countedset_remove_int(_countedSet, 2));
    XCTAssertEqual(2, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 1));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 3));

    XCTAssertEqual(success, tsearch_countedset_remove_all_ints(_countedSet));
    XCTAssertEqual(0, tsearch_countedset_get_count(_countedSet));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 1));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 3));
}


// ------------------------------------------------------------------------------------------
#pragma mark - Union Set
// ------------------------------------------------------------------------------------------
- (void)testUnionSet_PopulatedSetAndNull_EqualToPopulatedSetAndSuccess
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    XCTAssertEqual(success, tsearch_countedset_union(_countedSet, NULL));

    XCTAssertEqual(10 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(6, _countedSet->count);
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 8));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 4));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 3));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 0));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 3));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 5));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 9));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 10));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));
}


- (void)testUnionSet_PopulatedAndEmptySet_EqualToPopulatedSet
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    tsearch_countedset_ptr otherCountedSet = tsearch_countedset_init();
    XCTAssertEqual(0, otherCountedSet->count);

    XCTAssertEqual(success, tsearch_countedset_union(_countedSet, otherCountedSet));

    XCTAssertEqual(10 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(6, _countedSet->count);
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 8));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 4));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 3));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 0));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 3));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 5));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 9));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 10));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));

    tsearch_countedset_free(otherCountedSet);
}


- (void)testUnionSet_EmptyAndPopulatedSet_EqualToPopulatedSet
{
    tsearch_countedset_ptr otherCountedSet = tsearch_countedset_init();
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:integers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(0, _countedSet->count);
    XCTAssertEqual(6, otherCountedSet->count);

    XCTAssertEqual(success, tsearch_countedset_union(_countedSet, otherCountedSet));

    XCTAssertEqual(10 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(6, _countedSet->count);
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 8));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 4));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 3));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 0));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 3));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 5));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 9));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 10));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));

    tsearch_countedset_free(otherCountedSet);
}


- (void)testUnionSet_ThreeSameIntegersAndOneDifferent_AllIntegersWithSummedCounts
{
    tsearch_countedset_ptr otherCountedSet = tsearch_countedset_init();

    size_t count = 4;
    GNEInteger integers[] = { 23, 7834, 1, 24 };
    GNEInteger otherIntegers[] = { 24, 1, 23, 34780237 };

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];
    [self p_addIntegers:otherIntegers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(count, _countedSet->count);
    XCTAssertEqual(count, otherCountedSet->count);

    XCTAssertEqual(success, tsearch_countedset_union(_countedSet, otherCountedSet));

    XCTAssertEqual(5, _countedSet->count);

    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 1));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 23));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 24));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 7834));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 34780237));

    tsearch_countedset_free(otherCountedSet);
}


- (void)testUnionSet_ThreeDifferentSets_AllIntegersWithSummedCounts
{
    tsearch_countedset_ptr resultsPtr = tsearch_countedset_init();

    tsearch_countedset_ptr onePtr = tsearch_countedset_init();
    GNEInteger oneIntegers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:oneIntegers count:10 toCountedSet:onePtr];
    XCTAssertEqual(6, tsearch_countedset_get_count(onePtr));

    tsearch_countedset_ptr twoPtr = tsearch_countedset_init();
    GNEInteger twoIntegers[] = {8, 3, 101, 4};
    [self p_addIntegers:twoIntegers count:4 toCountedSet:twoPtr];
    XCTAssertEqual(4, tsearch_countedset_get_count(twoPtr));

    tsearch_countedset_ptr threePtr = tsearch_countedset_init();
    GNEInteger threeIntegers[] = {4, 4, 4, 9};
    [self p_addIntegers:threeIntegers count:4 toCountedSet:threePtr];
    XCTAssertEqual(2, tsearch_countedset_get_count(threePtr));

    tsearch_countedset_union(resultsPtr, onePtr);
    XCTAssertEqual(6, tsearch_countedset_get_count(resultsPtr));

    tsearch_countedset_union(resultsPtr, twoPtr);
    XCTAssertEqual(7, tsearch_countedset_get_count(resultsPtr));

    tsearch_countedset_union(resultsPtr, threePtr);
    XCTAssertEqual(8, tsearch_countedset_get_count(resultsPtr));
    XCTAssertEqual(true, tsearch_countedset_contains_int(resultsPtr, 4));
    XCTAssertEqual(6, tsearch_countedset_get_count_for_int(resultsPtr, 4));
    XCTAssertEqual(true, tsearch_countedset_contains_int(resultsPtr, 2));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(resultsPtr, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(resultsPtr, 8));
    XCTAssertEqual(3, tsearch_countedset_get_count_for_int(resultsPtr, 8));
    XCTAssertEqual(true, tsearch_countedset_contains_int(resultsPtr, 7));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(resultsPtr, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(resultsPtr, 3));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(resultsPtr, 3));
    XCTAssertEqual(true, tsearch_countedset_contains_int(resultsPtr, 0));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(resultsPtr, 0));
    XCTAssertEqual(true, tsearch_countedset_contains_int(resultsPtr, 101));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(resultsPtr, 101));
    XCTAssertEqual(true, tsearch_countedset_contains_int(resultsPtr, 9));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(resultsPtr, 9));

    tsearch_countedset_free(resultsPtr);
    tsearch_countedset_free(onePtr);
    tsearch_countedset_free(twoPtr);
    tsearch_countedset_free(threePtr);
}


- (void)testUnionSet_TwoRandomSets_AllIntegersWithSummedCounts
{
    NSArray *numbers1 = [self p_randomNumberArrayWithCount:1000];
    NSArray *numbers2 = [self p_randomNumberArrayWithCount:1000];

    tsearch_countedset_ptr gne1 = tsearch_countedset_init();
    tsearch_countedset_ptr gne2 = tsearch_countedset_init();
    [self p_addNumbers:numbers1 toCountedSet:gne1];
    [self p_addNumbers:numbers2 toCountedSet:gne2];

    NSCountedSet *ns1 = [self p_countedSetWithNumbers:numbers1];
    NSCountedSet *ns2 = [self p_countedSetWithNumbers:numbers2];

    [self p_assertGNECountedSet:gne1 isEqualToNSCountedSet:ns1];
    [self p_assertGNECountedSet:gne2 isEqualToNSCountedSet:ns2];

    XCTAssertEqual(success, tsearch_countedset_union(gne1, gne2));
    [ns1 unionSet:ns2];

    [self p_assertGNECountedSet:gne1 isEqualToNSCountedSet:ns1];

    tsearch_countedset_free(gne1);
    tsearch_countedset_free(gne2);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Intersect Set
// ------------------------------------------------------------------------------------------
- (void)testIntersectSet_ThreeDifferentSetsWithFour_OnlyFourRemains
{
    tsearch_countedset_ptr resultsPtr = tsearch_countedset_init();

    tsearch_countedset_ptr onePtr = tsearch_countedset_init();
    GNEInteger oneIntegers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:oneIntegers count:10 toCountedSet:onePtr];
    XCTAssertEqual(6, tsearch_countedset_get_count(onePtr));

    tsearch_countedset_ptr twoPtr = tsearch_countedset_init();
    GNEInteger twoIntegers[] = {8, 3, 0, 4};
    [self p_addIntegers:twoIntegers count:4 toCountedSet:twoPtr];
    XCTAssertEqual(4, tsearch_countedset_get_count(twoPtr));

    tsearch_countedset_ptr threePtr = tsearch_countedset_init();
    GNEInteger threeIntegers[] = {4, 4, 4, 4};
    [self p_addIntegers:threeIntegers count:4 toCountedSet:threePtr];
    XCTAssertEqual(1, tsearch_countedset_get_count(threePtr));

    tsearch_countedset_union(resultsPtr, onePtr);
    XCTAssertEqual(6, tsearch_countedset_get_count(resultsPtr));

    tsearch_countedset_intersect(resultsPtr, twoPtr);
    XCTAssertEqual(4, tsearch_countedset_get_count(resultsPtr));

    tsearch_countedset_intersect(resultsPtr, threePtr);
    XCTAssertEqual(1, tsearch_countedset_get_count(resultsPtr));
    XCTAssertEqual(true, tsearch_countedset_contains_int(resultsPtr, 4));
    XCTAssertEqual(7, tsearch_countedset_get_count_for_int(resultsPtr, 4));
    XCTAssertEqual(false, tsearch_countedset_contains_int(resultsPtr, 2));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(resultsPtr, 2));
    XCTAssertEqual(false, tsearch_countedset_contains_int(resultsPtr, 8));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(resultsPtr, 8));
    XCTAssertEqual(false, tsearch_countedset_contains_int(resultsPtr, 7));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(resultsPtr, 7));
    XCTAssertEqual(false, tsearch_countedset_contains_int(resultsPtr, 3));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(resultsPtr, 3));
    XCTAssertEqual(false, tsearch_countedset_contains_int(resultsPtr, 0));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(resultsPtr, 0));

    tsearch_countedset_free(resultsPtr);
    tsearch_countedset_free(onePtr);
    tsearch_countedset_free(twoPtr);
    tsearch_countedset_free(threePtr);
}


- (void)testIntersectSet_PopulatedSetAndNull_EmptySetAndSuccess
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    XCTAssertEqual(success, tsearch_countedset_intersect(_countedSet, NULL));

    XCTAssertEqual(10 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(0, _countedSet->count);
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 8));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 4));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 3));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 3));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 5));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 9));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 10));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));
}


- (void)testIntersectSet_PopulatedAndEmptySet_EqualToEmptySet
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    tsearch_countedset_ptr otherCountedSet = tsearch_countedset_init();
    XCTAssertEqual(0, otherCountedSet->count);

    XCTAssertEqual(success, tsearch_countedset_intersect(_countedSet, otherCountedSet));

    XCTAssertEqual(0, _countedSet->count);
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 8));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 4));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 3));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 3));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 5));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 9));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 10));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));

    tsearch_countedset_free(otherCountedSet);
}


- (void)testIntersectSet_EmptyAndPopulatedSet_EqualToEmptySet
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};

    tsearch_countedset_ptr otherCountedSet = tsearch_countedset_init();
    [self p_addIntegers:integers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(6, otherCountedSet->count);
    XCTAssertEqual(0, _countedSet->count);

    XCTAssertEqual(success, tsearch_countedset_intersect(_countedSet, otherCountedSet));

    XCTAssertEqual(0, _countedSet->count);
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 8));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 4));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 3));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 3));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 5));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 9));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 10));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));

    tsearch_countedset_free(otherCountedSet);
}


- (void)testIntersectSet_ThreeSameIntegersAndOneDifferent_ThreeSameIntegersWithSummedCounts
{
    tsearch_countedset_ptr otherCountedSet = tsearch_countedset_init();

    size_t count = 4;
    GNEInteger integers[] = { 23, 7834, 1, 24 };
    GNEInteger otherIntegers[] = { 24, 1, 23, 34780237 };

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];
    [self p_addIntegers:otherIntegers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(count, _countedSet->count);
    XCTAssertEqual(count, otherCountedSet->count);

    XCTAssertEqual(success, tsearch_countedset_intersect(_countedSet, otherCountedSet));

    XCTAssertEqual(3, _countedSet->count);

    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 1));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 23));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 24));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 7834));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 34780237));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 23));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 24));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 7834));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 34780237));

    tsearch_countedset_free(otherCountedSet);
}


- (void)testIntersectSet_TwoSetsWithTwoIntegersAndOneSetWithOneInteger_OneIntegerWithSummedCount
{
    size_t count = 2;
    GNEInteger integers[] = {1, 101};

    tsearch_countedset_ptr onePtr = tsearch_countedset_init();
    tsearch_countedset_ptr twoPtr = tsearch_countedset_init();
    tsearch_countedset_ptr threePtr = tsearch_countedset_init();

    [self p_addIntegers:integers count:count toCountedSet:onePtr];
    XCTAssertEqual(success, tsearch_countedset_add_int(twoPtr, 1));
    [self p_addIntegers:integers count:count toCountedSet:threePtr];

    XCTAssertEqual(2, tsearch_countedset_get_count(onePtr));
    XCTAssertEqual(1, tsearch_countedset_get_count(twoPtr));
    XCTAssertEqual(2, tsearch_countedset_get_count(threePtr));

    tsearch_countedset_ptr resultsPtr = tsearch_countedset_init();
    tsearch_countedset_union(resultsPtr, onePtr);
    XCTAssertEqual(2, tsearch_countedset_get_count(resultsPtr));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(resultsPtr, 1));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(resultsPtr, 101));

    tsearch_countedset_intersect(resultsPtr, twoPtr);
    XCTAssertEqual(1, tsearch_countedset_get_count(resultsPtr));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(resultsPtr, 1));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(resultsPtr, 101));

    tsearch_countedset_intersect(resultsPtr, threePtr);
    XCTAssertEqual(1, tsearch_countedset_get_count(resultsPtr));
    XCTAssertEqual(3, tsearch_countedset_get_count_for_int(resultsPtr, 1));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(resultsPtr, 101));
}


- (void)testIntersectSet_ThreeRandomSets_SameIntegersWithSummedCounts
{
    NSArray *numbers1 = [self p_randomNumberArrayWithCount:1000];
    NSArray *numbers2 = [self p_randomNumberArrayWithCount:1000];
    NSArray *numbers3 = [self p_randomNumberArrayWithCount:1000];

    tsearch_countedset_ptr gne1 = tsearch_countedset_init();
    tsearch_countedset_ptr gne2 = tsearch_countedset_init();
    tsearch_countedset_ptr gne3 = tsearch_countedset_init();
    tsearch_countedset_ptr resultsPtr = tsearch_countedset_init();
    [self p_addNumbers:numbers1 toCountedSet:gne1];
    [self p_addNumbers:numbers2 toCountedSet:gne2];
    [self p_addNumbers:numbers3 toCountedSet:gne3];

    NSCountedSet *ns1 = [self p_countedSetWithNumbers:numbers1];
    NSCountedSet *ns2 = [self p_countedSetWithNumbers:numbers2];
    NSCountedSet *ns3 = [self p_countedSetWithNumbers:numbers3];
    NSCountedSet *nsResults = [ns1 mutableCopy];

    [self p_assertGNECountedSet:gne1 isEqualToNSCountedSet:ns1];
    [self p_assertGNECountedSet:gne2 isEqualToNSCountedSet:ns2];
    [self p_assertGNECountedSet:gne3 isEqualToNSCountedSet:ns3];

    XCTAssertEqual(success, tsearch_countedset_union(resultsPtr, gne1));
    XCTAssertEqual(success, tsearch_countedset_intersect(resultsPtr, gne2));
    XCTAssertEqual(success, tsearch_countedset_intersect(resultsPtr, gne3));

    // -[NSCountedSet intersectSet:] resets each object's count to 1.
    [nsResults intersectSet:ns2];
    [nsResults intersectSet:ns3];

    XCTAssertEqual((size_t)nsResults.count, resultsPtr->count);
    for (NSNumber *number in nsResults.allObjects)
    {
        XCTAssertEqual(true, tsearch_countedset_contains_int(resultsPtr, (GNEInteger)number.integerValue));
    }

    GNEInteger *integersArray = NULL;
    size_t integersCount = 0;
    XCTAssertEqual(success, tsearch_countedset_copy_ints(resultsPtr, &integersArray, &integersCount));
    XCTAssertEqual((size_t)nsResults.count, integersCount);
    for (size_t i = 0; i < integersCount; i++)
    {
        GNEInteger integer = integersArray[i];
        XCTAssertTrue([nsResults containsObject:@(integer)]);
        XCTAssertTrue([nsResults countForObject:@(integer)] > 0);
    }

    size_t count = resultsPtr->count;
    _tsearch_countedset_node *nodes = resultsPtr->nodes;
    for (size_t i = 0; i < count; i++)
    {
        _tsearch_countedset_node node = nodes[i];
        size_t nsCount = 0;
        NSNumber *integerNumber = @(node.integer);
        if ([ns1 containsObject:integerNumber] &&
            [ns2 containsObject:integerNumber] &&
            [ns3 containsObject:integerNumber])
        {
            size_t count1 = (size_t)[ns1 countForObject:integerNumber];
            size_t count2 = (size_t)[ns2 countForObject:integerNumber];
            size_t count3 = (size_t)[ns3 countForObject:integerNumber];
            nsCount = count1 + count2 + count3;
        }
        XCTAssertEqual(nsCount, node.count);
    }

    tsearch_countedset_free(gne1);
    tsearch_countedset_free(gne2);
    tsearch_countedset_free(gne3);
    tsearch_countedset_free(resultsPtr);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Minus Set
// ------------------------------------------------------------------------------------------
- (void)testMinusSet_PopulatedSetAndNULL_EqualToPopulatedSetAndSuccess
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    XCTAssertEqual(success, tsearch_countedset_minus(_countedSet, NULL));

    XCTAssertEqual(10 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(6, _countedSet->count);
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 8));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 4));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 3));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 0));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 3));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 5));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 9));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 10));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));
}


- (void)testMinusSet_PopulatedAndEmptySet_EqualToPopulatedSet
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    tsearch_countedset_ptr otherCountedSet = tsearch_countedset_init();
    XCTAssertEqual(0, otherCountedSet->count);

    XCTAssertEqual(success, tsearch_countedset_minus(_countedSet, otherCountedSet));

    XCTAssertEqual(10 * sizeof(_tsearch_countedset_node), _countedSet->nodesCapacity);
    XCTAssertEqual(6, _countedSet->count);
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 8));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 4));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 3));
    XCTAssertEqual(2, tsearch_countedset_get_count_for_int(_countedSet, 0));

    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 3));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 5));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 9));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 10));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));

    tsearch_countedset_free(otherCountedSet);
}


- (void)testMinusSet_EmptyAndPopulatedSet_EqualToEmptySet
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};

    tsearch_countedset_ptr otherCountedSet = tsearch_countedset_init();
    [self p_addIntegers:integers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(6, otherCountedSet->count);
    XCTAssertEqual(0, _countedSet->count);

    XCTAssertEqual(success, tsearch_countedset_minus(_countedSet, otherCountedSet));

    XCTAssertEqual(0, _countedSet->count);
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 2));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 8));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 7));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 4));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 3));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 2));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 8));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 7));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 4));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 3));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 0));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 5));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 6));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 9));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 10));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, -1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 993999329));

    tsearch_countedset_free(otherCountedSet);
}


- (void)testMinusSet_ThreeSameIntegersAndOneDifferent_OneDifferentInteger
{
    tsearch_countedset_ptr otherCountedSet = tsearch_countedset_init();

    size_t count = 4;
    GNEInteger integers[] = { 23, 7834, 1, 24 };
    GNEInteger otherIntegers[] = { 24, 1, 23, 34780237 };

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];
    [self p_addIntegers:otherIntegers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(count, _countedSet->count);
    XCTAssertEqual(count, otherCountedSet->count);

    XCTAssertEqual(success, tsearch_countedset_minus(_countedSet, otherCountedSet));

    XCTAssertEqual(1, _countedSet->count);

    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 1));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 23));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 24));
    XCTAssertEqual(1, tsearch_countedset_get_count_for_int(_countedSet, 7834));
    XCTAssertEqual(0, tsearch_countedset_get_count_for_int(_countedSet, 34780237));

    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 1));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 23));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 24));
    XCTAssertEqual(true, tsearch_countedset_contains_int(_countedSet, 7834));
    XCTAssertEqual(false, tsearch_countedset_contains_int(_countedSet, 34780237));

    tsearch_countedset_free(otherCountedSet);
}


- (void)testMinusSet_TwoRandomSets_UniqueIntegersFromFirstSet
{
    NSArray *numbers1 = [self p_randomNumberArrayWithCount:1000];
    NSArray *numbers2 = [self p_randomNumberArrayWithCount:1000];

    tsearch_countedset_ptr gne1 = tsearch_countedset_init();
    tsearch_countedset_ptr gne2 = tsearch_countedset_init();
    [self p_addNumbers:numbers1 toCountedSet:gne1];
    [self p_addNumbers:numbers2 toCountedSet:gne2];

    NSCountedSet *ns1 = [self p_countedSetWithNumbers:numbers1];
    NSCountedSet *ns2 = [self p_countedSetWithNumbers:numbers2];

    [self p_assertGNECountedSet:gne1 isEqualToNSCountedSet:ns1];
    [self p_assertGNECountedSet:gne2 isEqualToNSCountedSet:ns2];

    XCTAssertEqual(success, tsearch_countedset_minus(gne1, gne2));

    [ns1 minusSet:ns2];

    [self p_assertGNECountedSet:gne1 isEqualToNSCountedSet:ns1];
    
    tsearch_countedset_free(gne1);
    tsearch_countedset_free(gne2);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Performance
// ------------------------------------------------------------------------------------------
- (void)testPerformance_AddTenThousandIntegers__0_016
{
    NSArray *numbers = [self p_tenThousandRandomIntegers_1];

    [self measureBlock:^()
    {
        tsearch_countedset_ptr countedSet = tsearch_countedset_init();
        [self p_addNumbers:numbers toCountedSet:countedSet];
        tsearch_countedset_free(countedSet);
    }];
}


- (void)testNSPerformance_AddTenThousandIntegers__0_004
{
    NSArray *numbers = [self p_tenThousandRandomIntegers_1];

    [self measureBlock:^()
    {
        NSCountedSet *countedSet = [NSCountedSet set];
        for (NSNumber *number in numbers)
        {
            [countedSet addObject:number];
        }
    }];
}


- (void)testPerformance_AddOneHundredThousandIntegers__0_700
{
    NSArray *numbers = [self p_oneHundredThousandRandomIntegers_1];

    [self measureBlock:^()
    {
        tsearch_countedset_ptr countedSet = tsearch_countedset_init();
        [self p_addNumbers:numbers toCountedSet:countedSet];
        tsearch_countedset_free(countedSet);
    }];
}


- (void)testNSPerformance_AddOneHundredThousandIntegers__0_026
{
    NSArray *numbers = [self p_oneHundredThousandRandomIntegers_1];

    [self measureBlock:^()
    {
        NSCountedSet *countedSet = [NSCountedSet set];
        for (NSNumber *number in numbers)
        {
            [countedSet addObject:number];
        }
    }];
}


- (void)testPerformance_OneHundredThousandContains__0_024
{
    NSArray *inserted = [self p_oneHundredThousandRandomIntegers_1];
    NSArray *targetNumbers = [self p_oneHundredThousandRandomIntegers_2];

    [self p_addNumbers:inserted toCountedSet:_countedSet];

    size_t targetCount = (size_t)targetNumbers.count;
    GNEInteger *targets = calloc(targetCount, sizeof(GNEInteger));
    for (size_t i = 0; i < targetCount; i++)
    {
        targets[i] = (GNEInteger)[targetNumbers[(NSUInteger)i] longLongValue];
    }

    __block NSUInteger count = 0;
    [self measureBlock:^()
    {
        for (size_t i = 0; i < targetCount; i++)
        {
            count += (tsearch_countedset_contains_int(_countedSet, targets[i])) ? 1 : 0;
        }
    }];

    XCTAssertEqual(633570, count);
}


- (void)testNSPerformance_OneHundredThousandContains__0_010
{
    NSArray *inserted = [self p_oneHundredThousandRandomIntegers_1];
    NSArray *targets = [self p_oneHundredThousandRandomIntegers_2];

    NSCountedSet *countedSet = [self p_countedSetWithNumbers:inserted];

    __block NSUInteger count = 0;
    [self measureBlock:^()
    {
        for (NSNumber *number in targets)
        {
            count += ([countedSet containsObject:number]) ? 1 : 0;
        }
    }];

    XCTAssertEqual(633570, count);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Helpers
// ------------------------------------------------------------------------------------------
- (void)p_assertCountedSet:(tsearch_countedset_ptr)countedSet
          containsIntegers:(GNEInteger *)integers
                     count:(size_t)count
{
    for (size_t i = 0; i < count; i++)
    {
        XCTAssertEqual(true, tsearch_countedset_contains_int(countedSet, integers[i]));
    }
}


- (void)p_assertGNECountedSet:(tsearch_countedset_ptr)gneCountedSet
        isEqualToNSCountedSet:(NSCountedSet *)nsCountedSet
{
    XCTAssertEqual((size_t)nsCountedSet.count, gneCountedSet->count);
    for (NSNumber *number in nsCountedSet)
    {
        GNEInteger integer = (GNEInteger)number.integerValue;
        size_t nsCount = (size_t)[nsCountedSet countForObject:number];
        size_t gneCount = tsearch_countedset_get_count_for_int(gneCountedSet, integer);
        XCTAssertEqual(nsCount, gneCount, @"%lld", (long long)integer);
    }
}


- (void)p_addIntegers:(GNEInteger *)integers
                count:(size_t)count
         toCountedSet:(tsearch_countedset_ptr)countedSet
{
    for (size_t i = 0; i < count; i++)
    {
        XCTAssertEqual(success, tsearch_countedset_add_int(countedSet, integers[i]));
        XCTAssertTrue(tsearch_countedset_get_count_for_int(countedSet, integers[i]) > 0, @"%lld", (long long)integers[i]);
    }
}


- (void)p_addNumbers:(NSArray *)numberArray toCountedSet:(tsearch_countedset_ptr)countedSet
{
    for (NSNumber *number in numberArray)
    {
        GNEInteger integer = (GNEInteger)number.integerValue;
        XCTAssertEqual(success, tsearch_countedset_add_int(countedSet, integer));
        XCTAssertTrue(tsearch_countedset_get_count_for_int(countedSet, integer) > 0, @"%lld", (long long)integer);
    }
}


- (NSArray *)p_randomNumberArrayWithCount:(size_t)count
{
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (size_t i = 0; i < count; i++)
    {
        u_int32_t integer = arc4random_uniform((u_int32_t)count);
        [mutableArray addObject:@(integer)];
    }

    return [mutableArray copy];
}


- (NSCountedSet *)p_countedSetWithNumbers:(NSArray *)numberArray
{
    NSCountedSet *countedSet = [NSCountedSet set];
    for (NSNumber *number in numberArray)
    {
        [countedSet addObject:number];
    }

    return countedSet;
}


- (NSArray<NSNumber *> *)p_tenThousandRandomIntegers_1
{
    NSArray *numbers = [self p_oneHundredThousandRandomIntegers_1];

    return [numbers subarrayWithRange:NSMakeRange(0, 10000)];
}


- (NSArray<NSNumber *> *)p_tenThousandRandomIntegers_2
{
    NSArray *numbers = [self p_oneHundredThousandRandomIntegers_2];

    return [numbers subarrayWithRange:NSMakeRange(0, 10000)];
}


- (NSArray<NSNumber *> *)p_oneHundredThousandRandomIntegers_1
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"random-integers-100000-1"
                                                                      ofType:@"txt"];
    NSString *string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSArray *stringArray = [string componentsSeparatedByString:@","];
    NSMutableArray *numbers = [NSMutableArray array];
    [stringArray enumerateObjectsUsingBlock:^(NSString *numberString, NSUInteger idx, BOOL *stop)
    {
        [numbers addObject:@(numberString.integerValue)];
    }];

    return [numbers copy];
}


- (NSArray<NSNumber *> *)p_oneHundredThousandRandomIntegers_2
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"random-integers-100000-2"
                                                                      ofType:@"txt"];
    NSString *string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSArray *stringArray = [string componentsSeparatedByString:@","];
    NSMutableArray *numbers = [NSMutableArray array];
    [stringArray enumerateObjectsUsingBlock:^(NSString *numberString, NSUInteger idx, BOOL *stop)
    {
        [numbers addObject:@(numberString.integerValue)];
    }];

    return [numbers copy];
}


@end
