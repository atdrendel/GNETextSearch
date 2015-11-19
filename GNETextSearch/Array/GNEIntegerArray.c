//
//  GNEIntegerArray.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 9/11/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "GNEIntegerArray.h"
#include "GNETextSearchPrivate.h"
#include <stdio.h>
#include <stddef.h>

// ------------------------------------------------------------------------------------------

int _GNEIntegerArrayIncreaseCapacityBy(GNEIntegerArrayPtr ptr, size_t increase);
int _GNEIntegerArrayIncreaseCapacityIfNeeded(GNEIntegerArrayPtr ptr);

// ------------------------------------------------------------------------------------------
#pragma mark - Array
// ------------------------------------------------------------------------------------------
typedef struct GNEIntegerArray
{
    GNEInteger *buffer;
    size_t bufferLength;
    size_t count;
} GNEIntegerArray;


GNEIntegerArrayPtr GNEIntegerArrayCreate(void)
{
    return GNEIntegerArrayCreateWithCapacity(10);
}


GNEIntegerArrayPtr GNEIntegerArrayCreateWithCapacity(size_t capacity)
{
    GNEIntegerArrayPtr ptr = calloc(1, sizeof(GNEIntegerArray));
    if (ptr == NULL) { return NULL; }

    ptr->buffer = NULL;
    ptr->bufferLength = 0;
    ptr->count = 0;

    size_t bufferLength = capacity * sizeof(GNEInteger);
    GNEInteger *buffer = calloc(capacity, sizeof(GNEInteger));
    if (buffer == NULL) { GNEIntegerArrayDestroy(ptr); return NULL; }

    ptr->buffer = buffer;
    ptr->bufferLength = bufferLength;
    ptr->count = 0;

    return ptr;
}


void GNEIntegerArrayDestroy(GNEIntegerArrayPtr ptr)
{
    if (ptr != NULL) {
        free(ptr->buffer);
        ptr->buffer = NULL;
        ptr->bufferLength = 0;
        ptr->count = 0;
        free(ptr);
    }
}


size_t GNEIntegerArrayGetCount(GNEIntegerArrayPtr ptr)
{

    return (ptr == NULL) ? 0 : ptr->count;
}


int GNEIntegerArrayAddInteger(GNEIntegerArrayPtr ptr, GNEInteger integer)
{
    if (ptr == NULL || _GNEIntegerArrayIncreaseCapacityIfNeeded(ptr) == FAILURE) { return FAILURE; }

    size_t count = ptr->count;
    ptr->buffer[count] = integer;
    ptr->count = count + 1;

    return SUCCESS;
}


int GNEIntegerArrayAddIntegersFromArray(GNEIntegerArrayPtr ptr, GNEIntegerArrayPtr otherPtr)
{
    if (ptr == NULL || otherPtr == NULL) { return FAILURE; }

    size_t otherCount = GNEIntegerArrayGetCount(otherPtr);
    for (size_t i = 0; i < otherCount; i++) {
        GNEInteger integer = GNEIntegerArrayGetIntegerAtIndex(otherPtr, i);
        if (GNEIntegerArrayAddInteger(ptr, integer) == FAILURE) { return FAILURE;}
    }

    return SUCCESS;
}


GNEInteger GNEIntegerArrayGetIntegerAtIndex(GNEIntegerArrayPtr ptr, size_t index)
{
    if (index >= GNEIntegerArrayGetCount(ptr)) { return SIZE_MAX; }
    return (ptr->buffer)[index];
}


void GNEIntegerArrayPrint(GNEIntegerArrayPtr ptr)
{
    size_t count = GNEIntegerArrayGetCount(ptr);
    printf("<GNEIntegerArray, %p> %lld integers\n{\n", ptr, (long long)count);
    for (size_t i = 0; i < count; i++) {
        printf("\t%lld\n", (long long)GNEIntegerArrayGetIntegerAtIndex(ptr, i));
    }
    printf("}\n");
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
/// Increases the number of integers the specified array can contain by the
/// specified number.
int _GNEIntegerArrayIncreaseCapacityBy(GNEIntegerArrayPtr ptr, size_t increase)
{
    if (ptr == NULL) { return FAILURE; }

    size_t bufferLength = ptr->bufferLength;
    size_t maxCount = bufferLength / sizeof(GNEInteger);
    size_t newCount = maxCount + increase;
    size_t newBufferLength = newCount * sizeof(GNEInteger);
    GNEInteger *newBuffer = realloc(ptr->buffer, newBufferLength);
    if (newBuffer == NULL) { return FAILURE; }

    ptr->buffer = newBuffer;
    ptr->bufferLength = newBufferLength;

    return SUCCESS;
}


/// Doubles the number of integers the specified array can contain if the array
/// only has one free space remaining. Otherwise, this method does nothing.
int _GNEIntegerArrayIncreaseCapacityIfNeeded(GNEIntegerArrayPtr ptr)
{
    if (ptr == NULL) { return FAILURE; }

    size_t count = ptr->count;
    size_t usedBuffer = count * sizeof(GNEInteger);
    size_t bufferLength = ptr->bufferLength;
    size_t emptySpacesRemaining = (bufferLength - usedBuffer) / sizeof(GNEInteger);

    if (emptySpacesRemaining == 1) {
        size_t previousMaxCount = count + emptySpacesRemaining;
        return _GNEIntegerArrayIncreaseCapacityBy(ptr, previousMaxCount); // Double the size.
    }

    return SUCCESS;
}
