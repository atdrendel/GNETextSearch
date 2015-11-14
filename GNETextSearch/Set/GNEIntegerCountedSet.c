//
//  GNEIntegerCountedSet.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/14/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "GNEIntegerCountedSet.h"
#include "GNETextSearchPrivate.h"

// ------------------------------------------------------------------------------------------

size_t _GNEIntegerCountedSetIndexForInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer);
size_t _GNEIntegerCountedSetInsertionIndexForInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer);

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
    if (ptr != NULL)
    {
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
    if (ptr == NULL || ptr->values == NULL) { return FAILURE; }

    

    return FAILURE;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
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

    GNEInteger lastInteger = values[(count - 1)].integer;
    if (lastInteger == integer) { return (count - 1); }

    size_t top = count - 1;
    size_t bottom = 0;

    while (top > bottom) {
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
