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

result _tsearch_stringbuf_increase_capacity(const tsearch_stringbuf_ptr ptr, const size_t newLength);
size_t _tsearch_stringbuf_get_max_char_count(const tsearch_stringbuf_ptr ptr);
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
        printf("C string parameter is not valid\n");
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


void tsearch_stringbuf_free(const tsearch_stringbuf_ptr ptr)
{
    if (ptr != NULL) {
        free(ptr->buffer);
        ptr->buffer = NULL;
        ptr->capacity = 0;
        ptr->length = 0;
        free(ptr);
    }
}


size_t tsearch_stringbuf_get_len(const tsearch_stringbuf_ptr ptr)
{
    return (ptr == NULL) ? 0 : ptr->length;
}


char tsearch_stringbuf_get_char_at_idx(const tsearch_stringbuf_ptr ptr, const size_t index)
{
    if (ptr == NULL || ptr->buffer == NULL || index >= ptr->length) { return '\0'; }
    return ptr->buffer[index];
}


result tsearch_stringbuf_append_char(const tsearch_stringbuf_ptr ptr, const char character)
{
    if (ptr == NULL || ptr->buffer == NULL) { return failure; }

    size_t newLength = 0;
    if (_tsearch_size_add_overflows(ptr->length, 1, &newLength)) { return failure; }

    if (_tsearch_stringbuf_increase_capacity(ptr, newLength) == failure) { return failure; }
    ptr->buffer[ptr->length] = character;
    ptr->length = newLength;
    return success;
}


int tsearch_stringbuf_append_cstring(const tsearch_stringbuf_ptr ptr, const char *cString, const size_t length)
{
#if DEBUG
    if (_is_valid_cstring(cString, length) == false) {
        printf("C string parameter is not valid\n");
        return failure;
    }
#endif

    if (ptr == NULL || ptr->buffer == NULL || cString == NULL) { return failure; }
    if (length == 0) { return success; }

    size_t newLength = 0;
    if (_tsearch_size_add_overflows(ptr->length, length, &newLength)) { return failure; }

    if (_tsearch_stringbuf_increase_capacity(ptr, newLength) == failure) { return failure; }

    memcpy(ptr->buffer + ptr->length, cString, length);
    ptr->length = newLength;

    return success;
}


const char * tsearch_stringbuf_copy_cstring(const tsearch_stringbuf_ptr ptr)
{
    if (ptr == NULL || ptr->buffer == NULL) { return NULL; }

    size_t length = ptr->length;

    size_t characterCount = 0;
    if (_tsearch_size_add_overflows(length, 1, &characterCount)) { return NULL; }

    size_t byteLength = 0;
    if (_tsearch_size_mul_overflows(characterCount, sizeof(char), &byteLength)) { return NULL; }

    char *ret = calloc(1, byteLength);
    if (ret == NULL) { return NULL; }

    memcpy(ret, ptr->buffer, length);
    ret[length] = '\0';

    return ret;
}


void tsearch_stringbuf_print(const tsearch_stringbuf_ptr ptr)
{
    if (ptr == NULL) {
        printf("<tsearch_stringbuf, %p> NULL\n", ptr);
        return;
    }

    const char *contents = tsearch_stringbuf_copy_cstring(ptr);
    printf("<tsearch_stringbuf, %p> %s\n", ptr, contents != NULL ? contents : "");
    free((void *)contents);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
int _tsearch_stringbuf_increase_capacity(const tsearch_stringbuf_ptr ptr, const size_t newLength)
{
    if (ptr == NULL || ptr->buffer == NULL) { return failure; }

    size_t maxCharacterCount = _tsearch_stringbuf_get_max_char_count(ptr);
    if (newLength < maxCharacterCount) {
        return success;
    }

    size_t doubleCapacity = 0;
    if (_tsearch_size_mul_overflows(ptr->capacity, 2, &doubleCapacity)) { return failure; }

    size_t requestedCapacity = 0;
    if (_tsearch_size_mul_overflows(newLength, sizeof(char), &requestedCapacity)) { return failure; }

    size_t newCapacity = (doubleCapacity > requestedCapacity) ? doubleCapacity : requestedCapacity;
    char *newBuffer = realloc(ptr->buffer, newCapacity);
    if (newBuffer == NULL) { return failure; }

    ptr->buffer = newBuffer;
    ptr->capacity = newCapacity;
    return success;
}


size_t _tsearch_stringbuf_get_max_char_count(const tsearch_stringbuf_ptr ptr)
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
