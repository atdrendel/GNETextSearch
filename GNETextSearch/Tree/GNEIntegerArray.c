//
//  GNEIntegerArray.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 9/11/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "GNEIntegerArray.h"


// ------------------------------------------------------------------------------------------


#define FAILURE 0
#define SUCCESS 1
#define FALSE 0
#define TRUE 1

int _GNEIntegerArrayIncreaseBufferLengthIfNeeded(GNEIntegerArrayPtr ptr);


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
    GNEIntegerArrayPtr ptr = malloc(sizeof(GNEIntegerArray));
    if (ptr == NULL) { return NULL; }

    ptr->buffer = NULL;
    ptr->bufferLength = 0;
    ptr->count = 0;

    size_t bufferLength = capacity * sizeof(GNEInteger);
    GNEInteger *buffer = malloc(bufferLength);
    if (buffer == NULL)
    {
        GNEIntegerArrayDestroy(ptr);
        return NULL;
    }

    ptr->buffer = buffer;
    ptr->bufferLength = bufferLength;
    ptr->count = 0;

    return ptr;
}


void GNEIntegerArrayDestroy(GNEIntegerArrayPtr ptr)
{
    if (ptr != NULL)
    {
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
    if (ptr == NULL || _GNEIntegerArrayIncreaseBufferLengthIfNeeded(ptr) == FAILURE) { return FALSE; }

    size_t count = ptr->count;
    ptr->buffer[count] = integer;
    ptr->count = count + 1;

    return SUCCESS;
}


GNEInteger GNEIntegerArrayGetIntegerAtIndex(GNEIntegerArrayPtr ptr, size_t index)
{
    if (index >= GNEIntegerArrayGetCount(ptr))
    {
        return SIZE_MAX;
    }

    return (ptr->buffer)[index];
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
int _GNEIntegerArrayIncreaseBufferLengthIfNeeded(GNEIntegerArrayPtr ptr)
{
    if (ptr == NULL) { return FAILURE; }

    size_t count = ptr->count;
    size_t usedBuffer = count * sizeof(GNEInteger);
    size_t bufferLength = ptr->bufferLength;
    size_t emptySpacesRemaining = (bufferLength - usedBuffer) / sizeof(GNEInteger);

    if (emptySpacesRemaining == 1)
    {
        size_t previousMaxCount = count + emptySpacesRemaining;
        size_t newBufferLength = (2 * previousMaxCount) * sizeof(GNEInteger);
        GNEInteger *newBuffer = realloc(ptr->buffer, newBufferLength);
        if (newBuffer == NULL)
        {
            GNEIntegerArrayDestroy(ptr);
            return FAILURE;
        }

        ptr->buffer = newBuffer;
        ptr->bufferLength = newBufferLength;
    }

    return SUCCESS;
}
