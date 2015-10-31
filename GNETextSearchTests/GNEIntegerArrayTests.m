//
//  GNEIntegerArrayTests.m
//  GNETextSearch
//
//  Created by Anthony Drendel on 9/13/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GNEIntegerArray.h"


// ------------------------------------------------------------------------------------------


typedef struct GNEIntegerArray
{
    GNEInteger *buffer;
    size_t bufferLength;
    size_t count;
} GNEIntegerArray;

int _GNEIntegerArrayIncreaseCapacityBy(GNEIntegerArrayPtr ptr, size_t increase);


// ------------------------------------------------------------------------------------------


@interface GNEIntegerArrayTests : XCTestCase
{
    GNEIntegerArrayPtr _arrayPtr;
}

@end


// ------------------------------------------------------------------------------------------


@implementation GNEIntegerArrayTests


// ------------------------------------------------------------------------------------------
#pragma mark - Set Up / Tear Down
// ------------------------------------------------------------------------------------------
- (void)setUp
{
    [super setUp];
    _arrayPtr = GNEIntegerArrayCreate();
}


- (void)tearDown
{
    GNEIntegerArrayDestroy(_arrayPtr);
    [super tearDown];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Intialization Tests
// ------------------------------------------------------------------------------------------
- (void)testIntialization_Default_Created
{
    GNEIntegerArrayDestroy(_arrayPtr);
    _arrayPtr = NULL;
    XCTAssertEqual(NULL, _arrayPtr);

    _arrayPtr = GNEIntegerArrayCreate();
    XCTAssertNotEqual(NULL, _arrayPtr);
    XCTAssertNotEqual(NULL, _arrayPtr->buffer);
    XCTAssertEqual(10 * sizeof(GNEInteger), _arrayPtr->bufferLength);
    XCTAssertEqual(0, _arrayPtr->count);
}


- (void)testIntialization_CapacityOf20_Created
{
    GNEIntegerArrayDestroy(_arrayPtr);
    _arrayPtr = NULL;
    XCTAssertEqual(NULL, _arrayPtr);

    _arrayPtr = GNEIntegerArrayCreateWithCapacity(20);
    XCTAssertNotEqual(NULL, _arrayPtr);
    XCTAssertNotEqual(NULL, _arrayPtr->buffer);
    XCTAssertEqual(20 * sizeof(GNEInteger), _arrayPtr->bufferLength);
    XCTAssertEqual(0, _arrayPtr->count);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Add Integer Tests
// ------------------------------------------------------------------------------------------
- (void)testAddInteger_Zero_AtIndexZero
{
    XCTAssertEqual(0, GNEIntegerArrayGetCount(_arrayPtr));

    GNEInteger index = 0;
    XCTAssertEqual(1, GNEIntegerArrayAddInteger(_arrayPtr, index));
    XCTAssertEqual(1, GNEIntegerArrayGetCount(_arrayPtr));
    XCTAssertEqual(index, GNEIntegerArrayGetIntegerAtIndex(_arrayPtr, 0));
    XCTAssertEqual(SIZE_MAX, GNEIntegerArrayGetIntegerAtIndex(_arrayPtr, 1));
}


- (void)testAddInteger_One_AtIndexZero
{
    XCTAssertEqual(0, GNEIntegerArrayGetCount(_arrayPtr));

    GNEInteger index = 1;
    XCTAssertEqual(1, GNEIntegerArrayAddInteger(_arrayPtr, index));
    XCTAssertEqual(1, GNEIntegerArrayGetCount(_arrayPtr));
    XCTAssertEqual(index, GNEIntegerArrayGetIntegerAtIndex(_arrayPtr, 0));
    XCTAssertEqual(SIZE_MAX, GNEIntegerArrayGetIntegerAtIndex(_arrayPtr, 1));
}


- (void)testAddInteger_OneTwoThree_AtIndexesZeroOneTwo
{
    XCTAssertEqual(0, GNEIntegerArrayGetCount(_arrayPtr));

    GNEInteger first = 1;
    GNEInteger second = 2;
    GNEInteger third = 3;
    XCTAssertEqual(1, GNEIntegerArrayAddInteger(_arrayPtr, first));
    XCTAssertEqual(1, GNEIntegerArrayAddInteger(_arrayPtr, second));
    XCTAssertEqual(1, GNEIntegerArrayAddInteger(_arrayPtr, third));
    XCTAssertEqual(3, GNEIntegerArrayGetCount(_arrayPtr));
    XCTAssertEqual(first, GNEIntegerArrayGetIntegerAtIndex(_arrayPtr, 0));
    XCTAssertEqual(second, GNEIntegerArrayGetIntegerAtIndex(_arrayPtr, 1));
    XCTAssertEqual(third, GNEIntegerArrayGetIntegerAtIndex(_arrayPtr, 2));
    XCTAssertEqual(SIZE_MAX, GNEIntegerArrayGetIntegerAtIndex(_arrayPtr, 3));
}


- (void)testAddInteger_OneThousandIntegers_AtCorrectIndexes
{
    XCTAssertEqual(0, GNEIntegerArrayGetCount(_arrayPtr));

    [self addIntegers:1000 toIntegerArray:_arrayPtr];
    XCTAssertEqual(1000, GNEIntegerArrayGetCount(_arrayPtr));

    for (size_t i = 0; i < 1000; i++)
    {
        XCTAssertEqual((GNEInteger)i, GNEIntegerArrayGetIntegerAtIndex(_arrayPtr, i));
    }
}


// ------------------------------------------------------------------------------------------
#pragma mark - Add Integers From Array
// ------------------------------------------------------------------------------------------
- (void)testAddIntegersFromArray_TenPlusTen_TwentyAtCorrectIndexes
{
    GNEIntegerArrayPtr ptr1 = GNEIntegerArrayCreateWithCapacity(10);
    GNEIntegerArrayPtr ptr2 = GNEIntegerArrayCreateWithCapacity(10);

    [self addIntegers:10 toIntegerArray:ptr1];
    [self addIntegers:10 startingAt:10 toIntegerArray:ptr2];

    XCTAssertEqual(10, ptr1->count);
    XCTAssertEqual(10, ptr2->count);

    XCTAssertEqual(1, GNEIntegerArrayAddIntegersFromArray(ptr1, ptr2));

    XCTAssertEqual(20, ptr1->count);
    XCTAssertEqual(10, ptr2->count);

    for (size_t i = 0; i < ptr1->count; i++)
    {
        XCTAssertEqual((GNEInteger)i, GNEIntegerArrayGetIntegerAtIndex(ptr1, i));
    }

    GNEIntegerArrayDestroy(ptr1);
    GNEIntegerArrayDestroy(ptr2);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Get Integer Tests
// ------------------------------------------------------------------------------------------
- (void)testAddInteger_Empty_ReturnSizeMax
{
    XCTAssertEqual(0, GNEIntegerArrayGetCount(_arrayPtr));
    XCTAssertEqual(SIZE_MAX, GNEIntegerArrayGetIntegerAtIndex(_arrayPtr, 0));
}


// ------------------------------------------------------------------------------------------
#pragma mark - Resize Buffer Tests
// ------------------------------------------------------------------------------------------
- (void)testResizeBuffer_AddTenIntegers_CapacityIs20
{
    XCTAssertEqual(0, GNEIntegerArrayGetCount(_arrayPtr));

    [self addIntegers:9 toIntegerArray:_arrayPtr];
    XCTAssertEqual(9, GNEIntegerArrayGetCount(_arrayPtr));
    XCTAssertEqual(10 * sizeof(GNEInteger), _arrayPtr->bufferLength);

    XCTAssertEqual(1, GNEIntegerArrayAddInteger(_arrayPtr, 9));
    XCTAssertEqual(20 * sizeof(GNEInteger), _arrayPtr->bufferLength);
}


- (void)testResizeBuffer_IncreaseCapacityFrom10To37_Increased
{
    GNEInteger start = 10;
    GNEInteger end = 37;

    XCTAssertEqual(0, GNEIntegerArrayGetCount(_arrayPtr));
    XCTAssertEqual(start * sizeof(GNEInteger), _arrayPtr->bufferLength);

    XCTAssertEqual(1, _GNEIntegerArrayIncreaseCapacityBy(_arrayPtr, end - start));
    XCTAssertEqual(end * sizeof(GNEInteger), _arrayPtr->bufferLength);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Helpers
// ------------------------------------------------------------------------------------------
- (void)addIntegers:(size_t)count toIntegerArray:(GNEIntegerArrayPtr)ptr
{
    [self addIntegers:count startingAt:0 toIntegerArray:ptr];
}


- (void)addIntegers:(size_t)count startingAt:(size_t)start toIntegerArray:(GNEIntegerArrayPtr)ptr
{
    for (size_t i = 0; i < count; i++)
    {
        XCTAssertEqual(1, GNEIntegerArrayAddInteger(ptr, (GNEInteger)(i + start)));
    }
}


@end
