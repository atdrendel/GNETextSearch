//
//  stringbuf.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/11/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "stringbuf.h"
#include "GNETextSearchPrivate.h"
#include <stdio.h>
#include <string.h>

// ------------------------------------------------------------------------------------------

result _tsearch_stringbuf_increase_capacity(tsearch_stringbuf_ptr ptr, size_t newLength);
size_t _tsearch_stringbuf_get_max_char_count(tsearch_stringbuf_ptr ptr);
bool _is_valid_cstring(const char *cString, const size_t length);

// ------------------------------------------------------------------------------------------
#pragma mark - String
// ------------------------------------------------------------------------------------------
typedef struct tsearch_stringbuf
{
    char *buffer;
    size_t capacity;
    size_t length;
} tsearch_stringbuf;


tsearch_stringbuf_ptr tsearch_stringbuf_init(void)
{
    size_t defaultCharacterCapacity = 5;
    char *buffer = calloc(defaultCharacterCapacity, sizeof(char));
    if (buffer == NULL) { return NULL; }

    tsearch_stringbuf_ptr ptr = calloc(1, sizeof(tsearch_stringbuf));
    if (ptr == NULL) { free(buffer); return NULL; }

    ptr->buffer = buffer;
    ptr->capacity = defaultCharacterCapacity * sizeof(char);
    ptr->length = 0;

    return ptr;
}


tsearch_stringbuf_ptr tsearch_stringbuf_init_with_cstring(const char *cString, const size_t length)
{
#if DEBUG
    if (_is_valid_cstring(cString, length) == false) {
        printf("C string parameter is not valid");
        return NULL;
    }
#endif

    tsearch_stringbuf_ptr ptr = tsearch_stringbuf_init();
    if (tsearch_stringbuf_append_cstring(ptr, cString, length) == failure) {
        tsearch_stringbuf_free(ptr);
        return NULL;
    }

    return ptr;
}


void tsearch_stringbuf_free(tsearch_stringbuf_ptr ptr)
{
    if (ptr != NULL) {
        free(ptr->buffer);
        ptr->buffer = NULL;
        ptr->capacity = 0;
        ptr->length = 0;
        free(ptr);
    }
}


size_t tsearch_stringbuf_get_len(tsearch_stringbuf_ptr ptr)
{
    return (ptr == NULL) ? 0 : ptr->length;
}


char tsearch_stringbuf_get_char_at_idx(tsearch_stringbuf_ptr ptr, size_t index)
{
    if (ptr == NULL || ptr->buffer == NULL || index >= ptr->length) { return '\0'; }
    return ptr->buffer[index];
}


int tsearch_stringbuf_append_cstring(tsearch_stringbuf_ptr ptr, const char *cString, const size_t length)
{
#if DEBUG
    if (_is_valid_cstring(cString, length) == false) {
        printf("C string parameter is not valid");
        return failure;
    }
#endif

    if (ptr == NULL || cString == NULL) { return failure; }
    if (length == 0) { return success; }

    size_t currentLength = ptr->length;
    size_t newLength = currentLength + length;
    if (_tsearch_stringbuf_increase_capacity(ptr, newLength) == failure) { return failure; }

    char *buffer = ptr->buffer;
    for (size_t i = 0; i < length; i++) {
        buffer[currentLength + i] = cString[i];
    }
    ptr->length = newLength;

    return success;
}


const char * tsearch_stringbuf_copy_cstring(tsearch_stringbuf_ptr ptr)
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


void tsearch_stringbuf_print(tsearch_stringbuf_ptr ptr)
{
    if (ptr == NULL) { printf("%p is NULL", ptr); }

    const char *contents = tsearch_stringbuf_copy_cstring(ptr);
    printf("<GNEMutableString, %p> %s\n", ptr, contents);
    free((void *)contents);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
int _tsearch_stringbuf_increase_capacity(tsearch_stringbuf_ptr ptr, size_t newLength)
{
    if (ptr == NULL || ptr->buffer == NULL) { return failure; }

    size_t maxCharacterCount = _tsearch_stringbuf_get_max_char_count(ptr);
    if (newLength >= maxCharacterCount) {
        size_t doubleCapacity = (2 * ptr->capacity);
        size_t requestedCapacity = (newLength * sizeof(char));
        size_t newCapacity = (doubleCapacity > requestedCapacity) ? doubleCapacity : requestedCapacity;
        char *newBuffer = realloc(ptr->buffer, newCapacity);
        if (newBuffer == NULL) { return failure; }
        ptr->buffer = newBuffer;
        ptr->capacity = newCapacity;
    }

    return success;
}


size_t _tsearch_stringbuf_get_max_char_count(tsearch_stringbuf_ptr ptr)
{
    if (ptr == NULL || ptr->buffer == NULL) { return 0; }

    size_t charSize = sizeof(char);
    size_t capacity = ptr->capacity;

    return (capacity / charSize);
}


bool _is_valid_cstring(const char *cString, const size_t length)
{
    if (cString == NULL) { return false; }

    for (size_t i = 0; i < length; i++) {
        if (cString[i] == '\0') { return false; }
    }

    return true;
}
