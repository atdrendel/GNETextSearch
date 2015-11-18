//
//  GNEIntegerCountedSet.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/14/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "GNEIntegerCountedSet.h"
#include "GNETextSearchPrivate.h"
#include <string.h>

// ------------------------------------------------------------------------------------------

int _GNEIntegerCountedSetAddInteger(GNEIntegerCountedSetPtr ptr, GNEInteger newInteger, size_t newCount);
int _GNEIntegerCountedSetRemoveInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer);
size_t _GNEIntegerCountedSetIndexForInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer);
size_t _GNEIntegerCountedSetInsertionIndexForInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer);
int _GNEIntegerCountedSetIncreaseValuesBufferIfNeeded(GNEIntegerCountedSetPtr ptr);

// ------------------------------------------------------------------------------------------
#pragma mark - Counted Set
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


GNEIntegerCountedSetPtr GNEIntegerCountedSetCreate(void)
{
    GNEIntegerCountedSetPtr ptr = calloc(1, sizeof(GNEIntegerCountedSet));
    if (ptr == NULL) { return NULL; }

    size_t count = 5;
    size_t size = sizeof(GNEIntegerCountedSetValue);
    GNEIntegerCountedSetValue *values = calloc(count, size);
    if (values == NULL) { GNEIntegerCountedSetDestroy(ptr); return NULL; }

    ptr->values = values;
    ptr->valuesCapacity = (count * size);
    ptr->count = 0;
    return ptr;
}


GNEIntegerCountedSetPtr GNEIntegerCountedSetCreateWithInteger(GNEInteger integer)
{
    GNEIntegerCountedSetPtr ptr = GNEIntegerCountedSetCreate();
    if (ptr == NULL) { return NULL; }
    if (GNEIntegerCountedSetAddInteger(ptr, integer) == FAILURE) {
        GNEIntegerCountedSetDestroy(ptr);
        return NULL;
    }
    return ptr;
}


void GNEIntegerCountedSetDestroy(GNEIntegerCountedSetPtr ptr)
{
    if (ptr != NULL) {
        free(ptr->values);
        ptr->values = NULL;
        ptr->valuesCapacity = 0;
        ptr->count = 0;
        free(ptr);
    }
}


int GNEIntegerCountedSetContainsInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    return (_GNEIntegerCountedSetIndexForInteger(ptr, integer) == SIZE_MAX) ? FALSE : TRUE;
}

size_t GNEIntegerCountedSetCountForInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    if (ptr == NULL || ptr->values == NULL) { return 0; }
    size_t index = _GNEIntegerCountedSetIndexForInteger(ptr, integer);
    if (index == SIZE_MAX || index >= ptr->count) { return 0; }
    return ptr->values[index].count;
}


int GNEIntegerCountedSetAddInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    return _GNEIntegerCountedSetAddInteger(ptr, integer, 1);
}


int GNEIntegerCountedSetUnionSet(GNEIntegerCountedSetPtr ptr, GNEIntegerCountedSetPtr otherPtr)
{
    if (ptr == NULL || ptr->values == NULL) { return FAILURE; }
    if (otherPtr == NULL || otherPtr->values == NULL) { return FAILURE; }

    size_t otherCount = otherPtr->count;
    GNEIntegerCountedSetValue *otherValues = otherPtr->values;
    for (size_t i = 0; i < otherCount; i++) {
        GNEIntegerCountedSetValue otherValue = otherValues[i];
        int result = _GNEIntegerCountedSetAddInteger(ptr, otherValue.integer, otherValue.count);
        if (result == FAILURE) { return FAILURE; }
    }
    return SUCCESS;
}


int GNEIntegerCountedSetIntersectSet(GNEIntegerCountedSetPtr ptr, GNEIntegerCountedSetPtr otherPtr)
{
    if (ptr == NULL || ptr->values == NULL) { return FAILURE; }
    if (otherPtr == NULL || otherPtr->values == NULL) { return FAILURE; }

    size_t count = ptr->count;

    // Copy all of the counted set's values so that we can iterate over them
    // while modifying the set.
    GNEIntegerCountedSetValue valuesCopy[count];
    for (size_t i = 0; i < count; i++) {
        valuesCopy[i] = ptr->values[i];
    }

    for (size_t i = 0; i < count; i++) {
        GNEIntegerCountedSetValue value = valuesCopy[i];
        size_t index = _GNEIntegerCountedSetIndexForInteger(otherPtr, value.integer);
        if (index == SIZE_MAX) {
            int result = _GNEIntegerCountedSetRemoveInteger(ptr, value.integer);
            if (result == FAILURE) { return FAILURE; }
        } else {
            size_t valueCount = GNEIntegerCountedSetCountForInteger(otherPtr, value.integer);
            int result = _GNEIntegerCountedSetAddInteger(ptr, value.integer, valueCount);
            if (result == FAILURE) { return FAILURE; }
        }
    }
    return SUCCESS;
}


int GNEIntegerCountedSetMinusSet(GNEIntegerCountedSetPtr ptr, GNEIntegerCountedSetPtr otherPtr)
{
    if (ptr == NULL || ptr->values == NULL) { return FAILURE; }
    if (otherPtr == NULL || otherPtr->values == NULL) { return FAILURE; }

    size_t otherCount = otherPtr->count;
    GNEIntegerCountedSetValue *otherValues = otherPtr->values;
    for (size_t i = 0; i < otherCount; i++) {
        GNEIntegerCountedSetValue otherValue = otherValues[i];
        size_t index = _GNEIntegerCountedSetIndexForInteger(ptr, otherValue.integer);
        if (index == SIZE_MAX || index >= ptr->count) { continue; }
        if (otherValue.count >= ptr->values[index].count) {
            int result = _GNEIntegerCountedSetRemoveInteger(ptr, otherValue.integer);
            if (result == FAILURE) { return FAILURE; }
        } else {
            ptr->values[index].count -= otherValue.count;
        }
    }
    return SUCCESS;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
/// Adds the specified integer to the specified counted set. The specified count is added
/// to the integer's current count.
int _GNEIntegerCountedSetAddInteger(GNEIntegerCountedSetPtr ptr, GNEInteger newInteger, size_t newCount)
{
    if (ptr == NULL || ptr->values == NULL) { return FAILURE; }
    if (newCount < 1) { return SUCCESS; }
    size_t index = _GNEIntegerCountedSetInsertionIndexForInteger(ptr, newInteger);

    // If the returned index points to the same value, increase its count.
    if (ptr->count > 0 && ptr->values[index].integer == newInteger) {
        ptr->values[index].count += newCount;
    } else {
        if (_GNEIntegerCountedSetIncreaseValuesBufferIfNeeded(ptr) == FAILURE) { return FAILURE; }
        GNEIntegerCountedSetValue *values = ptr->values;
        size_t count = ptr->count;
        // Move all the values above the insertion index up by one.
        memmove(&(values[index + 1]), &(values[index]), sizeof(GNEIntegerCountedSetValue) * (count - index));
        values[index].integer = newInteger;
        values[index].count = newCount;
        ptr->count += 1;
    }

    return SUCCESS;
}


int _GNEIntegerCountedSetRemoveInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    if (ptr == NULL || ptr->values == NULL) { return FAILURE; }
    size_t index = _GNEIntegerCountedSetIndexForInteger(ptr, integer);
    if (index == SIZE_MAX) { return SUCCESS; }
    if (index >= ptr->count) { return FAILURE; } // This should never happen.
    GNEIntegerCountedSetValue *values = ptr->values;
    size_t count = ptr->count;
    memmove(&(values[index]), &(values[index + 1]), sizeof(GNEIntegerCountedSetValue) * (count - index - 1));

    // Clear out the previous last value.
    values[count - 1].integer = 0;
    values[count - 1].count = 0;

    ptr->count -= 1;

    return SUCCESS;
}


/// Returns the index at which the specified integer can be found. If the counted set
/// does not include the integer, returns SIZE_MAX.
size_t _GNEIntegerCountedSetIndexForInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    if (ptr == NULL || ptr->values == NULL) { return SIZE_MAX; }
    size_t count = ptr->count;
    if (count == 0) { return SIZE_MAX; }

    GNEIntegerCountedSetValue *values = ptr->values;

    GNEInteger firstInteger = values[0].integer;
    if (firstInteger == integer) { return 0; }
    if (firstInteger > integer) { return SIZE_MAX; }

    GNEInteger lastInteger = values[(count - 1)].integer;
    if (lastInteger == integer) { return (count - 1); }
    if (lastInteger < integer) { return SIZE_MAX; }

    size_t top = count - 1;
    size_t bottom = 0;

    while (top >= bottom) {
        size_t middle = ((top + bottom) / 2);
        GNEInteger middleInteger = values[middle].integer;
        if (integer > middleInteger) { bottom = middle + 1; }
        else if (integer < middleInteger) { top = middle - 1; }
        else { return middle; }
    }

    return SIZE_MAX;
}


/// Returns the index at which the specified index should be inserted into the counted set or
/// SIZE_MAX if the counted set pointer was NULL.
size_t _GNEIntegerCountedSetInsertionIndexForInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    if (ptr == NULL || ptr->values == NULL) { return SIZE_MAX; }
    size_t count = ptr->count;
    if (count == 0) { return 0; }

    GNEIntegerCountedSetValue *values = ptr->values;

    GNEInteger firstInteger = values[0].integer;
    if (firstInteger >= integer) { return 0; }

    GNEInteger lastInteger = values[(count - 1)].integer;
    if (lastInteger < integer) { return count; }
    if (lastInteger == integer) { return (count - 1); }

    size_t top = count - 1;
    size_t bottom = 0;

    while (top > bottom) {
        size_t middle = ((top + bottom) / 2);
        GNEInteger middleInteger = values[middle].integer;

        if (integer > middleInteger) { bottom = middle + 1; }
        else { top = middle - 1; }
    }

    while (values[bottom].integer < integer) { bottom += 1; }

    return bottom;
}


int _GNEIntegerCountedSetIncreaseValuesBufferIfNeeded(GNEIntegerCountedSetPtr ptr)
{
    if (ptr == NULL || ptr->values == NULL) { return FAILURE; }

    size_t count = ptr->count;
    size_t capacity = ptr->valuesCapacity;
    size_t emptySpaces = (capacity / sizeof(GNEIntegerCountedSetValue)) - count;
    if (emptySpaces <= 2) {
        size_t newCapacity = capacity * 2;
        GNEIntegerCountedSetValue *newValues = realloc(ptr->values, newCapacity);
        if (newValues == NULL) { return FAILURE; }
        ptr->values = newValues;
        ptr->valuesCapacity = newCapacity;
    }

    return SUCCESS;
}
