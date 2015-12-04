//
//  GNEIntegerCountedSetTests.m
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/14/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GNEIntegerCountedSet.h"
#import "GNETextSearchPrivate.h"


// ------------------------------------------------------------------------------------------


typedef struct _CountedSetNode * _CountedSetNodePtr;

typedef struct _CountedSetNode
{
    GNEInteger integer;
    size_t count;
    int balance;
    size_t left;
    size_t right;
} _CountedSetNode;


typedef struct GNEIntegerCountedSet
{
    _CountedSetNode *nodes;
    _CountedSetNodePtr root;
    size_t count; // The number of nodes whose count > 0.
    size_t nodesCapacity;
    size_t insertIndex;
} GNEIntegerCountedSet;


// ------------------------------------------------------------------------------------------


@interface GNEIntegerCountedSetTests : XCTestCase
{
    GNEIntegerCountedSetPtr _countedSet;
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
    _countedSet = GNEIntegerCountedSetCreate();
}


- (void)tearDown {
    GNEIntegerCountedSetDestroy(_countedSet);
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
    XCTAssertEqual(5 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(0, _countedSet->count);
}


- (void)testInitialization_Zero_CorrectValueAndCount
{
    GNEIntegerCountedSetDestroy(_countedSet);
    _countedSet = NULL;
    XCTAssertTrue(_countedSet == NULL);

    GNEInteger integer = 0;

    _countedSet = GNEIntegerCountedSetCreateWithInteger(integer);
    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(5 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(1, _countedSet->count);
    XCTAssertEqual(1, _countedSet->insertIndex);
    XCTAssertEqual(integer, _countedSet->nodes[0].integer);
    XCTAssertEqual(1, _countedSet->nodes[0].count);
}


- (void)testInitialization_One_CorrectValueAndCount
{
    GNEIntegerCountedSetDestroy(_countedSet);
    _countedSet = NULL;
    XCTAssertTrue(_countedSet == NULL);

    GNEInteger integer = 1;

    _countedSet = GNEIntegerCountedSetCreateWithInteger(integer);
    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(5 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(1, _countedSet->count);
    XCTAssertEqual(1, _countedSet->insertIndex);
    XCTAssertEqual(integer, _countedSet->nodes[0].integer);
    XCTAssertEqual(1, _countedSet->nodes[0].count);
}


- (void)testInitialization_99999999999_CorrectValueAndCount
{
    GNEIntegerCountedSetDestroy(_countedSet);
    _countedSet = NULL;
    XCTAssertTrue(_countedSet == NULL);

    GNEInteger integer = 99999999999;

    _countedSet = GNEIntegerCountedSetCreateWithInteger(integer);
    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(5 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(1, _countedSet->count);
    XCTAssertEqual(1, _countedSet->insertIndex);
    XCTAssertEqual(integer, _countedSet->nodes[0].integer);
    XCTAssertEqual(1, _countedSet->nodes[0].count);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Count
// ------------------------------------------------------------------------------------------
- (void)testCount_NullPointer_Zero
{
    XCTAssertEqual(0, GNEIntegerCountedSetGetCount(NULL));
}


- (void)testCount_EmptySet_Zero
{
    XCTAssertEqual(0, _countedSet->count);
    XCTAssertEqual(0, GNEIntegerCountedSetGetCount(_countedSet));
}


- (void)testCount_OneInteger_One
{
    XCTAssertEqual(1, GNEIntegerCountedSetAddInteger(_countedSet, 12343232));
    XCTAssertEqual(1, _countedSet->count);
    XCTAssertEqual(1, GNEIntegerCountedSetGetCount(_countedSet));
}


- (void)testCount_OneIntegerTwoTimes_One
{
    XCTAssertEqual(1, GNEIntegerCountedSetAddInteger(_countedSet, 12343232));
    XCTAssertEqual(1, GNEIntegerCountedSetAddInteger(_countedSet, 12343232));
    XCTAssertEqual(1, _countedSet->count);
    XCTAssertEqual(1, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 12343232));
}


- (void)testCount_FiveIntegersMinusOne_Four
{
    XCTAssertEqual(1, GNEIntegerCountedSetAddInteger(_countedSet, 12343232));
    XCTAssertEqual(1, GNEIntegerCountedSetAddInteger(_countedSet, 3223));
    XCTAssertEqual(1, GNEIntegerCountedSetAddInteger(_countedSet, 3242351245));
    XCTAssertEqual(1, GNEIntegerCountedSetAddInteger(_countedSet, 12312));
    XCTAssertEqual(1, GNEIntegerCountedSetAddInteger(_countedSet, 0));
    XCTAssertEqual(5, _countedSet->count);
    XCTAssertEqual(5, GNEIntegerCountedSetGetCount(_countedSet));

    XCTAssertEqual(1, GNEIntegerCountedSetRemoveInteger(_countedSet, 0));
    XCTAssertEqual(4, _countedSet->count);
    XCTAssertEqual(4, GNEIntegerCountedSetGetCount(_countedSet));
}


- (void)testCount_RandomIntegers_EqualsCountOfNSSet
{
    NSArray *numbers = [self p_tenThousandRandomIntegers_1];
    for (NSNumber *number in numbers)
    {
        XCTAssertEqual(1, GNEIntegerCountedSetAddInteger(_countedSet, (GNEInteger)number.integerValue));
    }
    NSSet *set = [NSSet setWithArray:numbers];
    XCTAssertEqual((size_t)set.count, _countedSet->count);
    XCTAssertEqual((size_t)set.count, GNEIntegerCountedSetGetCount(_countedSet));
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
    XCTAssertEqual(1, GNEIntegerCountedSetCopyIntegers(_countedSet, &results, &resultsCount));
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
    XCTAssertEqual(4, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetRemoveInteger(_countedSet, 4));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetRemoveInteger(_countedSet, 7));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCount(_countedSet));

    GNEInteger *results = NULL;
    size_t resultsCount = 0;
    XCTAssertEqual(1, GNEIntegerCountedSetCopyIntegers(_countedSet, &results, &resultsCount));
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

    XCTAssertEqual(countedSet.count, GNEIntegerCountedSetGetCount(_countedSet));

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
    XCTAssertEqual(1, GNEIntegerCountedSetCopyIntegers(_countedSet, &results, &resultsCount));
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
    XCTAssertEqual(5 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(count, _countedSet->count);

    [self p_assertCountedSet:_countedSet containsIntegers:integers count:count];

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 4));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 6));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, -1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 993999329));
}


- (void)testAddIntegers_ZeroOneAndTwo_CorrectValuesAndCount
{
    size_t count = 3;
    GNEInteger integers[] = {0, 1, 2};

    [self p_addIntegers:integers count:3 toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(5 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(count, _countedSet->count);

    [self p_assertCountedSet:_countedSet containsIntegers:integers count:count];

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 4));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 6));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, -1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 993999329));
}


- (void)testAddIntegers_ZeroOneTwoThree_CorrectValuesAndCount
{
    size_t count = 4;
    GNEInteger integers[] = {0, 1, 2, 3};

    [self p_addIntegers:integers count:4 toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(10 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(count, _countedSet->count);

    [self p_assertCountedSet:_countedSet containsIntegers:integers count:count];

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 4));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 6));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, -1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 993999329));
}


- (void)testAddIntegers_AddTenFourTimes_NoDuplicatesCorrectValuesAndCount
{
    size_t count = 1;
    GNEInteger integers[] = {10, 10, 10, 10};

    [self p_addIntegers:integers count:4 toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(5 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(count, _countedSet->count);

    [self p_assertCountedSet:_countedSet containsIntegers:integers count:count];
}


- (void)testAddIntegers_LeftLeftRotation_CorrectRotation
{
    GNEInteger integers[] = {8, 7, 2};
    size_t count = 3;

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    _CountedSetNode *nodes = _countedSet->nodes;

    XCTAssertEqual(7, nodes[0].integer);
    XCTAssertEqual(2, nodes[0].left);
    XCTAssertEqual(1, nodes[0].right);

    XCTAssertEqual(8, nodes[1].integer);
    XCTAssertEqual(SIZE_MAX, nodes[1].left);
    XCTAssertEqual(SIZE_MAX, nodes[1].right);

    XCTAssertEqual(2, nodes[2].integer);
    XCTAssertEqual(SIZE_MAX, nodes[2].left);
    XCTAssertEqual(SIZE_MAX, nodes[2].right);

    XCTAssertEqual(3, GNEIntegerCountedSetGetCount(_countedSet));

    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
}


- (void)testAddIntegers_LeftRightRotation_CorrectRotation
{
    GNEInteger integers[] = {8, 2, 7};
    size_t count = 3;

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    _CountedSetNode *nodes = _countedSet->nodes;

    XCTAssertEqual(7, nodes[0].integer);
    XCTAssertEqual(1, nodes[0].left);
    XCTAssertEqual(2, nodes[0].right);

    XCTAssertEqual(2, nodes[1].integer);
    XCTAssertEqual(SIZE_MAX, nodes[1].left);
    XCTAssertEqual(SIZE_MAX, nodes[1].right);

    XCTAssertEqual(8, nodes[2].integer);
    XCTAssertEqual(SIZE_MAX, nodes[2].left);
    XCTAssertEqual(SIZE_MAX, nodes[2].right);

    XCTAssertEqual(3, GNEIntegerCountedSetGetCount(_countedSet));

    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
}


- (void)testAddIntegers_RightLeftRotation_CorrectRotation
{
    GNEInteger integers[] = {2, 8, 7};
    size_t count = 3;

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    _CountedSetNode *nodes = _countedSet->nodes;

    XCTAssertEqual(7, nodes[0].integer);
    XCTAssertEqual(2, nodes[0].left);
    XCTAssertEqual(1, nodes[0].right);

    XCTAssertEqual(8, nodes[1].integer);
    XCTAssertEqual(SIZE_MAX, nodes[1].left);
    XCTAssertEqual(SIZE_MAX, nodes[1].right);

    XCTAssertEqual(2, nodes[2].integer);
    XCTAssertEqual(SIZE_MAX, nodes[2].left);
    XCTAssertEqual(SIZE_MAX, nodes[2].right);

    XCTAssertEqual(3, GNEIntegerCountedSetGetCount(_countedSet));

    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
}


- (void)testAddIntegers_RightRightRotation_CorrectRotation
{
    GNEInteger integers[] = {2, 7, 8};
    size_t count = 3;

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    _CountedSetNode *nodes = _countedSet->nodes;

    XCTAssertEqual(7, nodes[0].integer);
    XCTAssertEqual(1, nodes[0].left);
    XCTAssertEqual(2, nodes[0].right);

    XCTAssertEqual(2, nodes[1].integer);
    XCTAssertEqual(SIZE_MAX, nodes[1].left);
    XCTAssertEqual(SIZE_MAX, nodes[1].right);

    XCTAssertEqual(8, nodes[2].integer);
    XCTAssertEqual(SIZE_MAX, nodes[2].left);
    XCTAssertEqual(SIZE_MAX, nodes[2].right);

    XCTAssertEqual(3, GNEIntegerCountedSetGetCount(_countedSet));

    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
}


- (void)testAddIntegers_TwelveIntegersNeedingThreeRotations_CorrectCounts
{
    GNEInteger integers[] = {7, 2, 8, 1, 3, 6, 5, 4, 9, 11, 12, 13};
    size_t count = 12;

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    XCTAssertEqual(count, GNEIntegerCountedSetGetCount(_countedSet));

    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 1));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 1));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 3));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 3));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 6));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 6));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 5));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 5));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 4));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 4));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 9));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 9));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 11));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 11));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 12));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 12));
    XCTAssertEqual(1, GNEIntegerCountedSetContainsInteger(_countedSet, 13));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 13));

    XCTAssertEqual(0, GNEIntegerCountedSetContainsInteger(_countedSet, 10));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 10));
    XCTAssertEqual(0, GNEIntegerCountedSetContainsInteger(_countedSet, 0));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 0));
    XCTAssertEqual(0, GNEIntegerCountedSetContainsInteger(_countedSet, 2342342));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2342342));
    XCTAssertEqual(0, GNEIntegerCountedSetContainsInteger(_countedSet, -1));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, -1));
}


- (void)testAddIntegers_AddTenNumbers_NoDuplicatesAndCorrectCounts
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->nodes != NULL);
    XCTAssertEqual(10 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(6, _countedSet->count);
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 4));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 3));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 0));

    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 4));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 3));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 0));

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 5));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 6));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 9));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 10));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, -1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 993999329));
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
    XCTAssertEqual(10240 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
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
    XCTAssertEqual(0, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetRemoveInteger(_countedSet, 1));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCount(_countedSet));
}


- (void)testRemove_RemoveOnlyInteger_ZeroCount
{
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 1));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetRemoveInteger(_countedSet, 1));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCount(_countedSet));
}


- (void)testRemove_OneIntegerTwiceRemove_ZeroCount
{
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 1));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 1));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 1));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetRemoveInteger(_countedSet, 1));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 1));
}


- (void)testRemove_ThreeIntegersRemoveFirst_TwoRemaining
{
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 1));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 2));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 3));
    XCTAssertEqual(3, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetRemoveInteger(_countedSet, 1));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 1));
}


- (void)testRemove_ThreeIntegersRemoveAll_ZeroCounts
{
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 1));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 2));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 3));
    XCTAssertEqual(3, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetRemoveAllIntegers(_countedSet));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 1));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 3));
}


- (void)testRemove_ThreeIntegersRemoveSecondAndThenRemoveAll_ZeroCounts
{
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 1));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 2));
    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(_countedSet, 3));
    XCTAssertEqual(3, GNEIntegerCountedSetGetCount(_countedSet));

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetRemoveInteger(_countedSet, 2));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 1));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 3));

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetRemoveAllIntegers(_countedSet));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCount(_countedSet));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 1));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 3));
}


// ------------------------------------------------------------------------------------------
#pragma mark - Union Set
// ------------------------------------------------------------------------------------------
- (void)testUnionSet_PopulatedAndEmptySet_EqualToPopulatedSet
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    GNEIntegerCountedSetPtr otherCountedSet = GNEIntegerCountedSetCreate();
    XCTAssertEqual(0, otherCountedSet->count);

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetUnionSet(_countedSet, otherCountedSet));

    XCTAssertEqual(10 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(6, _countedSet->count);
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 4));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 3));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 0));

    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 4));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 3));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 0));

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 5));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 6));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 9));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 10));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, -1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 993999329));

    GNEIntegerCountedSetDestroy(otherCountedSet);
}


- (void)testUnionSet_EmptyAndPopulatedSet_EqualToPopulatedSet
{
    GNEIntegerCountedSetPtr otherCountedSet = GNEIntegerCountedSetCreate();
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:integers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(0, _countedSet->count);
    XCTAssertEqual(6, otherCountedSet->count);

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetUnionSet(_countedSet, otherCountedSet));

    XCTAssertEqual(10 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(6, _countedSet->count);
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 4));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 3));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 0));

    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 4));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 3));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 0));

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 5));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 6));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 9));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 10));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, -1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 993999329));

    GNEIntegerCountedSetDestroy(otherCountedSet);
}


- (void)testUnionSet_ThreeSameIntegersAndOneDifferent_AllIntegersWithSummedCounts
{
    GNEIntegerCountedSetPtr otherCountedSet = GNEIntegerCountedSetCreate();

    size_t count = 4;
    GNEInteger integers[] = { 23, 7834, 1, 24 };
    GNEInteger otherIntegers[] = { 24, 1, 23, 34780237 };

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];
    [self p_addIntegers:otherIntegers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(count, _countedSet->count);
    XCTAssertEqual(count, otherCountedSet->count);

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetUnionSet(_countedSet, otherCountedSet));

    XCTAssertEqual(5, _countedSet->count);

    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 1));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 23));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 24));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7834));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 34780237));

    GNEIntegerCountedSetDestroy(otherCountedSet);
}


- (void)testUnionSet_TwoRandomSets_AllIntegersWithSummedCounts
{
    NSArray *numbers1 = [self p_randomNumberArrayWithCount:1000];
    NSArray *numbers2 = [self p_randomNumberArrayWithCount:1000];

    GNEIntegerCountedSetPtr gne1 = GNEIntegerCountedSetCreate();
    GNEIntegerCountedSetPtr gne2 = GNEIntegerCountedSetCreate();
    [self p_addNumbers:numbers1 toCountedSet:gne1];
    [self p_addNumbers:numbers2 toCountedSet:gne2];

    NSCountedSet *ns1 = [self p_countedSetWithNumbers:numbers1];
    NSCountedSet *ns2 = [self p_countedSetWithNumbers:numbers2];

    [self p_assertGNECountedSet:gne1 isEqualToNSCountedSet:ns1];
    [self p_assertGNECountedSet:gne2 isEqualToNSCountedSet:ns2];

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetUnionSet(gne1, gne2));
    [ns1 unionSet:ns2];

    [self p_assertGNECountedSet:gne1 isEqualToNSCountedSet:ns1];

    GNEIntegerCountedSetDestroy(gne1);
    GNEIntegerCountedSetDestroy(gne2);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Intersect Set
// ------------------------------------------------------------------------------------------
- (void)testIntersectSet_PopulatedAndEmptySet_EqualToEmptySet
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    GNEIntegerCountedSetPtr otherCountedSet = GNEIntegerCountedSetCreate();
    XCTAssertEqual(0, otherCountedSet->count);

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetIntersectSet(_countedSet, otherCountedSet));

    XCTAssertEqual(0, _countedSet->count);
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 4));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 3));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 0));

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 4));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 3));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 0));

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 5));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 6));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 9));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 10));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, -1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 993999329));

    GNEIntegerCountedSetDestroy(otherCountedSet);
}


- (void)testIntersectSet_EmptyAndPopulatedSet_EqualToEmptySet
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};

    GNEIntegerCountedSetPtr otherCountedSet = GNEIntegerCountedSetCreate();
    [self p_addIntegers:integers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(6, otherCountedSet->count);
    XCTAssertEqual(0, _countedSet->count);

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetIntersectSet(_countedSet, otherCountedSet));

    XCTAssertEqual(0, _countedSet->count);
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 4));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 3));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 0));

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 4));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 3));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 0));

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 5));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 6));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 9));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 10));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, -1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 993999329));

    GNEIntegerCountedSetDestroy(otherCountedSet);
}


- (void)testIntersectSet_ThreeSameIntegersAndOneDifferent_ThreeSameIntegersWithSummedCounts
{
    GNEIntegerCountedSetPtr otherCountedSet = GNEIntegerCountedSetCreate();

    size_t count = 4;
    GNEInteger integers[] = { 23, 7834, 1, 24 };
    GNEInteger otherIntegers[] = { 24, 1, 23, 34780237 };

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];
    [self p_addIntegers:otherIntegers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(count, _countedSet->count);
    XCTAssertEqual(count, otherCountedSet->count);

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetIntersectSet(_countedSet, otherCountedSet));

    XCTAssertEqual(3, _countedSet->count);

    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 1));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 23));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 24));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7834));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 34780237));

    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 1));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 23));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 24));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 7834));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 34780237));

    GNEIntegerCountedSetDestroy(otherCountedSet);
}


- (void)testIntersectSet_TwoRandomSets_SameIntegersWithSummedCounts
{
    NSArray *numbers1 = [self p_randomNumberArrayWithCount:1000];
    NSArray *numbers2 = [self p_randomNumberArrayWithCount:1000];

    GNEIntegerCountedSetPtr gne1 = GNEIntegerCountedSetCreate();
    GNEIntegerCountedSetPtr gne2 = GNEIntegerCountedSetCreate();
    [self p_addNumbers:numbers1 toCountedSet:gne1];
    [self p_addNumbers:numbers2 toCountedSet:gne2];

    NSCountedSet *ns1 = [self p_countedSetWithNumbers:numbers1];
    NSCountedSet *nsIntersect = [ns1 mutableCopy];
    NSCountedSet *ns2 = [self p_countedSetWithNumbers:numbers2];

    [self p_assertGNECountedSet:gne1 isEqualToNSCountedSet:ns1];
    [self p_assertGNECountedSet:gne2 isEqualToNSCountedSet:ns2];

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetIntersectSet(gne1, gne2));

    // -[NSCountedSet intersectSet:] resets each object's count to 1.
    [nsIntersect intersectSet:ns2];

    XCTAssertEqual((size_t)nsIntersect.count, gne1->count);
    for (NSNumber *number in nsIntersect.allObjects)
    {
        XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(gne1, (GNEInteger)number.integerValue));
    }

    size_t count = gne1->count;
    _CountedSetNode *nodes = gne1->nodes;
    for (size_t i = 0; i < count; i++)
    {
        _CountedSetNode node = nodes[i];
        size_t nsCount = 0;
        NSNumber *integerNumber = @(node.integer);
        if ([ns1 containsObject:integerNumber] && [ns2 containsObject:integerNumber])
        {
            nsCount = (size_t)([ns1 countForObject:integerNumber] + [ns2 countForObject:integerNumber]);
        }
        XCTAssertEqual(nsCount, node.count);
    }

    GNEIntegerCountedSetDestroy(gne1);
    GNEIntegerCountedSetDestroy(gne2);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Minus Set
// ------------------------------------------------------------------------------------------
- (void)testMinusSet_PopulatedAndEmptySet_EqualToPopulatedSet
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};
    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    GNEIntegerCountedSetPtr otherCountedSet = GNEIntegerCountedSetCreate();
    XCTAssertEqual(0, otherCountedSet->count);

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetMinusSet(_countedSet, otherCountedSet));

    XCTAssertEqual(10 * sizeof(_CountedSetNode), _countedSet->nodesCapacity);
    XCTAssertEqual(6, _countedSet->count);
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 4));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 3));
    XCTAssertEqual(2, GNEIntegerCountedSetGetCountForInteger(_countedSet, 0));

    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 4));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 3));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 0));

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 5));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 6));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 9));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 10));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, -1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 993999329));

    GNEIntegerCountedSetDestroy(otherCountedSet);
}


- (void)testMinusSet_EmptyAndPopulatedSet_EqualToEmptySet
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};

    GNEIntegerCountedSetPtr otherCountedSet = GNEIntegerCountedSetCreate();
    [self p_addIntegers:integers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(6, otherCountedSet->count);
    XCTAssertEqual(0, _countedSet->count);

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetMinusSet(_countedSet, otherCountedSet));

    XCTAssertEqual(0, _countedSet->count);
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 2));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 8));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 4));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 3));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 0));

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 2));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 8));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 7));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 4));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 3));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 0));

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 5));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 6));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 9));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 10));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, -1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 993999329));

    GNEIntegerCountedSetDestroy(otherCountedSet);
}


- (void)testMinusSet_ThreeSameIntegersAndOneDifferent_OneDifferentInteger
{
    GNEIntegerCountedSetPtr otherCountedSet = GNEIntegerCountedSetCreate();

    size_t count = 4;
    GNEInteger integers[] = { 23, 7834, 1, 24 };
    GNEInteger otherIntegers[] = { 24, 1, 23, 34780237 };

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];
    [self p_addIntegers:otherIntegers count:count toCountedSet:otherCountedSet];

    XCTAssertEqual(count, _countedSet->count);
    XCTAssertEqual(count, otherCountedSet->count);

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetMinusSet(_countedSet, otherCountedSet));

    XCTAssertEqual(1, _countedSet->count);

    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 1));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 23));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 24));
    XCTAssertEqual(1, GNEIntegerCountedSetGetCountForInteger(_countedSet, 7834));
    XCTAssertEqual(0, GNEIntegerCountedSetGetCountForInteger(_countedSet, 34780237));

    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 1));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 23));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 24));
    XCTAssertEqual(TRUE, GNEIntegerCountedSetContainsInteger(_countedSet, 7834));
    XCTAssertEqual(FALSE, GNEIntegerCountedSetContainsInteger(_countedSet, 34780237));

    GNEIntegerCountedSetDestroy(otherCountedSet);
}


- (void)testMinusSet_TwoRandomSets_UniqueIntegersFromFirstSet
{
    NSArray *numbers1 = [self p_randomNumberArrayWithCount:1000];
    NSArray *numbers2 = [self p_randomNumberArrayWithCount:1000];

    GNEIntegerCountedSetPtr gne1 = GNEIntegerCountedSetCreate();
    GNEIntegerCountedSetPtr gne2 = GNEIntegerCountedSetCreate();
    [self p_addNumbers:numbers1 toCountedSet:gne1];
    [self p_addNumbers:numbers2 toCountedSet:gne2];

    NSCountedSet *ns1 = [self p_countedSetWithNumbers:numbers1];
    NSCountedSet *ns2 = [self p_countedSetWithNumbers:numbers2];

    [self p_assertGNECountedSet:gne1 isEqualToNSCountedSet:ns1];
    [self p_assertGNECountedSet:gne2 isEqualToNSCountedSet:ns2];

    XCTAssertEqual(SUCCESS, GNEIntegerCountedSetMinusSet(gne1, gne2));

    [ns1 minusSet:ns2];

    [self p_assertGNECountedSet:gne1 isEqualToNSCountedSet:ns1];
    
    GNEIntegerCountedSetDestroy(gne1);
    GNEIntegerCountedSetDestroy(gne2);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Performance
// ------------------------------------------------------------------------------------------
- (void)testPerformance_AddTenThousandIntegers__0_016
{
    NSArray *numbers = [self p_tenThousandRandomIntegers_1];

    [self measureBlock:^()
    {
        GNEIntegerCountedSetPtr countedSet = GNEIntegerCountedSetCreate();
        [self p_addNumbers:numbers toCountedSet:countedSet];
        GNEIntegerCountedSetDestroy(countedSet);
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
        GNEIntegerCountedSetPtr countedSet = GNEIntegerCountedSetCreate();
        [self p_addNumbers:numbers toCountedSet:countedSet];
        GNEIntegerCountedSetDestroy(countedSet);
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
            count += (GNEIntegerCountedSetContainsInteger(_countedSet, targets[i])) ? 1 : 0;
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
- (void)p_assertCountedSet:(GNEIntegerCountedSetPtr)countedSet
          containsIntegers:(GNEInteger *)integers
                     count:(size_t)count
{
    for (size_t i = 0; i < count; i++)
    {
        GNEIntegerCountedSetContainsInteger(countedSet, integers[i]);
    }
}


- (void)p_assertGNECountedSet:(GNEIntegerCountedSetPtr)gneCountedSet
        isEqualToNSCountedSet:(NSCountedSet *)nsCountedSet
{
    XCTAssertEqual((size_t)nsCountedSet.count, gneCountedSet->count);
    for (NSNumber *number in nsCountedSet)
    {
        GNEInteger integer = (GNEInteger)number.integerValue;
        size_t nsCount = (size_t)[nsCountedSet countForObject:number];
        size_t gneCount = GNEIntegerCountedSetGetCountForInteger(gneCountedSet, integer);
        XCTAssertEqual(nsCount, gneCount, @"%lld", (long long)integer);
    }
}


- (void)p_addIntegers:(GNEInteger *)integers
                count:(size_t)count
         toCountedSet:(GNEIntegerCountedSetPtr)countedSet
{
    for (size_t i = 0; i < count; i++)
    {
        XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(countedSet, integers[i]));
        XCTAssertTrue(GNEIntegerCountedSetGetCountForInteger(countedSet, integers[i]) > 0, @"%lld", (long long)integers[i]);
    }
}


- (void)p_addNumbers:(NSArray *)numberArray toCountedSet:(GNEIntegerCountedSetPtr)countedSet
{
    for (NSNumber *number in numberArray)
    {
        GNEInteger integer = (GNEInteger)number.integerValue;
        XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(countedSet, integer));
        XCTAssertTrue(GNEIntegerCountedSetGetCountForInteger(countedSet, integer) > 0, @"%lld", (long long)integer);
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
