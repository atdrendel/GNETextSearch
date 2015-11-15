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


typedef struct GNEIntegerCountedSetValue
{
    GNEInteger integer;
    size_t count;
} GNEIntegerCountedSetValue;


typedef struct GNEIntegerCountedSet
{
    GNEIntegerCountedSetValue *values;
    size_t valuesCapacity;
    size_t count;
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
    XCTAssertTrue(_countedSet->values != NULL);
    XCTAssertEqual(5 * sizeof(GNEIntegerCountedSetValue), _countedSet->valuesCapacity);
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
    XCTAssertTrue(_countedSet->values != NULL);
    XCTAssertEqual(5 * sizeof(GNEIntegerCountedSetValue), _countedSet->valuesCapacity);
    XCTAssertEqual(1, _countedSet->count);
    XCTAssertEqual(integer, _countedSet->values[0].integer);
    XCTAssertEqual(1, _countedSet->values[0].count);
}


- (void)testInitialization_One_CorrectValueAndCount
{
    GNEIntegerCountedSetDestroy(_countedSet);
    _countedSet = NULL;
    XCTAssertTrue(_countedSet == NULL);

    GNEInteger integer = 1;

    _countedSet = GNEIntegerCountedSetCreateWithInteger(integer);
    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->values != NULL);
    XCTAssertEqual(5 * sizeof(GNEIntegerCountedSetValue), _countedSet->valuesCapacity);
    XCTAssertEqual(1, _countedSet->count);
    XCTAssertEqual(integer, _countedSet->values[0].integer);
    XCTAssertEqual(1, _countedSet->values[0].count);
}


- (void)testInitialization_99999999999_CorrectValueAndCount
{
    GNEIntegerCountedSetDestroy(_countedSet);
    _countedSet = NULL;
    XCTAssertTrue(_countedSet == NULL);

    GNEInteger integer = 99999999999;

    _countedSet = GNEIntegerCountedSetCreateWithInteger(integer);
    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->values != NULL);
    XCTAssertEqual(5 * sizeof(GNEIntegerCountedSetValue), _countedSet->valuesCapacity);
    XCTAssertEqual(1, _countedSet->count);
    XCTAssertEqual(integer, _countedSet->values[0].integer);
    XCTAssertEqual(1, _countedSet->values[0].count);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Add/Count Integers
// ------------------------------------------------------------------------------------------
- (void)testAddIntegers_ZeroAndOne_CorrectValuesAndCount
{
    size_t count = 2;
    GNEInteger integers[] = {0, 1};
    size_t counts[] = {1, 1};

    [self p_addIntegers:integers count:2 toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->values != NULL);
    XCTAssertEqual(5 * sizeof(GNEIntegerCountedSetValue), _countedSet->valuesCapacity);
    XCTAssertEqual(count, _countedSet->count);
    [self p_assertIntegersInCountedSet:_countedSet equalIntegers:integers count:count];
    [self p_assertCountsInCountedSet:_countedSet equalCounts:counts count:count];
}


- (void)testAddIntegers_ZeroOneAndTwo_CorrectValuesAndCount
{
    size_t count = 3;
    GNEInteger integers[] = {0, 1, 2};
    size_t counts[] = {1, 1, 1};

    [self p_addIntegers:integers count:3 toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->values != NULL);
    XCTAssertEqual(5 * sizeof(GNEIntegerCountedSetValue), _countedSet->valuesCapacity);
    XCTAssertEqual(count, _countedSet->count);
    [self p_assertIntegersInCountedSet:_countedSet equalIntegers:integers count:count];
    [self p_assertCountsInCountedSet:_countedSet equalCounts:counts count:count];
}


- (void)testAddIntegers_ZeroOneTwoThree_CorrectValuesAndCount
{
    size_t count = 4;
    GNEInteger integers[] = {0, 1, 2, 3};
    size_t counts[] = {1, 1, 1, 1};

    [self p_addIntegers:integers count:4 toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->values != NULL);
    XCTAssertEqual(10 * sizeof(GNEIntegerCountedSetValue), _countedSet->valuesCapacity);
    XCTAssertEqual(count, _countedSet->count);
    [self p_assertIntegersInCountedSet:_countedSet equalIntegers:integers count:count];
    [self p_assertCountsInCountedSet:_countedSet equalCounts:counts count:count];
}


- (void)testAddIntegers_AddTenFourTimes_NoDuplicatesCorrectValuesAndCount
{
    size_t count = 1;
    GNEInteger integers[] = {10, 10, 10, 10};
    size_t counts[] = {4};

    [self p_addIntegers:integers count:4 toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->values != NULL);
    XCTAssertEqual(5 * sizeof(GNEIntegerCountedSetValue), _countedSet->valuesCapacity);
    XCTAssertEqual(count, _countedSet->count);
    [self p_assertIntegersInCountedSet:_countedSet equalIntegers:integers count:count];
    [self p_assertCountsInCountedSet:_countedSet equalCounts:counts count:count];
}


- (void)testAddIntegers_AddTenNumbers_NoDuplicatesAndCorrectCounts
{
    size_t count = 10;
    GNEInteger integers[] = {2, 8, 7, 4, 4, 8, 3, 0, 7, 0};

    [self p_addIntegers:integers count:count toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->values != NULL);
    XCTAssertEqual(10 * sizeof(GNEIntegerCountedSetValue), _countedSet->valuesCapacity);
    XCTAssertEqual(6, _countedSet->count);
    XCTAssertEqual(1, GNEIntegerCountedSetCountForInteger(_countedSet, 2));
    XCTAssertEqual(2, GNEIntegerCountedSetCountForInteger(_countedSet, 8));
    XCTAssertEqual(2, GNEIntegerCountedSetCountForInteger(_countedSet, 7));
    XCTAssertEqual(2, GNEIntegerCountedSetCountForInteger(_countedSet, 4));
    XCTAssertEqual(1, GNEIntegerCountedSetCountForInteger(_countedSet, 3));
    XCTAssertEqual(2, GNEIntegerCountedSetCountForInteger(_countedSet, 0));
}


- (void)testAddIntegers_AddOneMillionIntegersFourTimes_NoDuplicatesCorrectValuesAndCounts
{
    size_t count = 1000000;
    GNEInteger *integers = calloc(4 * count, sizeof(GNEInteger));
    size_t *counts = calloc(count, sizeof(size_t));
    for (size_t i = 0; i < (4 * count); i++)
    {
        integers[i] = i % count;
        if (i < count) { counts[i] = 4; }
    }

    [self p_addIntegers:integers count:(4 * count) toCountedSet:_countedSet];

    XCTAssertTrue(_countedSet != NULL);
    XCTAssertTrue(_countedSet->values != NULL);
    XCTAssertEqual(1310720 * sizeof(GNEIntegerCountedSetValue), _countedSet->valuesCapacity);
    XCTAssertEqual(count, _countedSet->count);
    [self p_assertIntegersInCountedSet:_countedSet equalIntegers:integers count:count];
    [self p_assertCountsInCountedSet:_countedSet equalCounts:counts count:count];

    free(integers);
    free(counts);
}


- (void)testAddIntegers_AddOneHundredThousandRandomIntegers_EqualToNSCountedSet
{
    size_t count = 10000;
    NSArray *numbers = [self p_randomNumberArrayWithCount:count];
    [self p_addNumbers:numbers toCountedSet:_countedSet];
    NSCountedSet *nsCountedSet = [self p_countedSetWithNumbers:numbers];
    [self p_assertGNECountedSet:_countedSet isEqualToNSCountedSet:nsCountedSet];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Helpers
// ------------------------------------------------------------------------------------------
- (void)p_assertIntegersInCountedSet:(GNEIntegerCountedSetPtr)countedSet
                       equalIntegers:(GNEInteger *)integers
                               count:(size_t)count
{
    for (size_t i = 0; i < count; i++)
    {
        XCTAssertEqual(integers[i], countedSet->values[i].integer);
    }
}


- (void)p_assertCountsInCountedSet:(GNEIntegerCountedSetPtr)countedSet
                       equalCounts:(size_t *)counts
                             count:(size_t)count
{
    for (size_t i = 0; i < count; i++)
    {
        XCTAssertEqual(counts[i], countedSet->values[i].count);
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
        size_t gneCount = GNEIntegerCountedSetCountForInteger(gneCountedSet, integer);
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
        XCTAssertTrue(GNEIntegerCountedSetCountForInteger(countedSet, integers[i]) > 0, @"%lld", (long long)integers[i]);
    }
}


- (void)p_addNumbers:(NSArray *)numberArray toCountedSet:(GNEIntegerCountedSetPtr)countedSet
{
    for (NSNumber *number in numberArray)
    {
        GNEInteger integer = (GNEInteger)number.integerValue;
        XCTAssertEqual(SUCCESS, GNEIntegerCountedSetAddInteger(countedSet, integer));
        XCTAssertTrue(GNEIntegerCountedSetCountForInteger(countedSet, integer) > 0, @"%lld", (long long)integer);
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


@end
