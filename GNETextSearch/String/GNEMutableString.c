//
//  GNEMutableString.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/11/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "GNEMutableString.h"
#include "GNETextSearchPrivate.h"
#include <stdio.h>
#include <string.h>

// ------------------------------------------------------------------------------------------

int _GNEMutableStringIncreaseCapacityIfNeeded(GNEMutableStringPtr ptr, size_t newLength);
size_t _GNEMutableStringGetMaxCharacterCount(GNEMutableStringPtr ptr);
int _IsValidCString(const char *cString, const size_t length);

// ------------------------------------------------------------------------------------------
#pragma mark - String
// ------------------------------------------------------------------------------------------
typedef struct GNEMutableString
{
    char *buffer;
    size_t bufferCapacity;
    size_t length;
} GNEMutableString;


GNEMutableStringPtr GNEMutableStringCreate(void)
{
    size_t defaultCharacterCapacity = 5;
    char *buffer = calloc(defaultCharacterCapacity, sizeof(char));
    if (buffer == NULL) { return NULL; }

    GNEMutableStringPtr ptr = calloc(1, sizeof(GNEMutableString));
    if (ptr == NULL) { free(buffer); return NULL; }

    ptr->buffer = buffer;
    ptr->bufferCapacity = defaultCharacterCapacity * sizeof(char);
    ptr->length = 0;

    return ptr;
}


GNEMutableStringPtr GNEMutableStringCreateWithCString(const char *cString, const size_t length)
{
#if DEBUG
    if (_IsValidCString(cString, length) == FALSE) {
        printf("C string parameter is not valid");
        return NULL;
    }
#endif

    GNEMutableStringPtr ptr = GNEMutableStringCreate();
    if (GNEMutableStringAppendCString(ptr, cString, length) == FAILURE) {
        GNEMutableStringDestroy(ptr);
        return NULL;
    }

    return ptr;
}


void GNEMutableStringDestroy(GNEMutableStringPtr ptr)
{
    if (ptr != NULL) {
        free(ptr->buffer);
        ptr->buffer = NULL;
        ptr->bufferCapacity = 0;
        ptr->length = 0;
        free(ptr);
    }
}


size_t GNEMutableStringGetLength(GNEMutableStringPtr ptr)
{
    return (ptr == NULL) ? 0 : ptr->length;
}


char GNEMutableStringGetCharAtIndex(GNEMutableStringPtr ptr, size_t index)
{
    if (ptr == NULL || ptr->buffer == NULL || index >= ptr->length) { return '\0'; }
    return ptr->buffer[index];
}


int GNEMutableStringAppendCString(GNEMutableStringPtr ptr, const char *cString, const size_t length)
{
#if DEBUG
    if (_IsValidCString(cString, length) == FALSE) {
        printf("C string parameter is not valid");
        return FAILURE;
    }
#endif

    if (ptr == NULL || cString == NULL) { return FAILURE; }
    if (length == 0) { return SUCCESS; }

    size_t currentLength = ptr->length;
    size_t newLength = currentLength + length;
    if (_GNEMutableStringIncreaseCapacityIfNeeded(ptr, newLength) == FAILURE) { return FAILURE; }

    char *buffer = ptr->buffer;
    for (size_t i = 0; i < length; i++) {
        buffer[currentLength + i] = cString[i];
    }
    ptr->length = newLength;

    return SUCCESS;
}


const char * GNEMutableStringCopyContents(GNEMutableStringPtr ptr)
{
    if (ptr == NULL || ptr->buffer == NULL) { return NULL; }

    size_t length = ptr->length;

    char *ret = calloc(length + 1, sizeof(char));
    if (ret == NULL) { return NULL; }

    char *buffer = ptr->buffer;
    for (size_t i = 0; i < length; i++) {
        ret[i] = buffer[i];
    }
    ret[length] = '\0';

    return ret;
}


void GNEMutableStringPrint(GNEMutableStringPtr ptr)
{
    if (ptr == NULL) { printf("%p is NULL", ptr); }

    const char *contents = GNEMutableStringCopyContents(ptr);
    printf("<GNEMutableString, %p> %s\n", ptr, contents);
    free((void *)contents);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
int _GNEMutableStringIncreaseCapacityIfNeeded(GNEMutableStringPtr ptr, size_t newLength)
{
    if (ptr == NULL || ptr->buffer == NULL) { return FAILURE; }

    size_t maxCharacterCount = _GNEMutableStringGetMaxCharacterCount(ptr);
    if (newLength >= maxCharacterCount) {
        size_t doubleCapacity = (2 * ptr->bufferCapacity);
        size_t requestedCapacity = (newLength * sizeof(char));
        size_t newBufferCapacity = (doubleCapacity > requestedCapacity) ? doubleCapacity : requestedCapacity;
        char *newBuffer = realloc(ptr->buffer, newBufferCapacity);
        if (newBuffer == NULL) { return FAILURE; }
        ptr->buffer = newBuffer;
        ptr->bufferCapacity = newBufferCapacity;
    }

    return SUCCESS;
}


size_t _GNEMutableStringGetMaxCharacterCount(GNEMutableStringPtr ptr)
{
    if (ptr == NULL || ptr->buffer == NULL) { return 0; }

    size_t charSize = sizeof(char);
    size_t bufferCapacity = ptr->bufferCapacity;

    return (bufferCapacity / charSize);
}


int _IsValidCString(const char *cString, const size_t length)
{
    if (cString == NULL) { return FALSE; }

    for (size_t i = 0; i < length; i++) {
        if (cString[i] == '\0') { return FALSE; }
    }

    return TRUE;
}
