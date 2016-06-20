//
//  GNEUnicodeUtilities.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 1/1/16.
//  Copyright © 2016 Gone East LLC. All rights reserved.
//
//
// Copyright (c) 2008-2009 Bjoern Hoehrmann <bjoern@hoehrmann.de>
// http://bjoern.hoehrmann.de/utf-8/decoder/dfa/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions
// of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
// TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

#include "GNEUnicodeUtilities.h"
#include "GNEUnicodeWordBoundary.h"
#include "GNETextSearchPrivate.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>


#define UTF8_ACCEPT 0
#define UTF8_REJECT 1


// ------------------------------------------------------------------------------------------
#pragma mark - Decode
// ------------------------------------------------------------------------------------------
static const uint8_t utf8d[] =
{
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 00..1f
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 20..3f
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 40..5f
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 60..7f
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9, // 80..9f
	7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, // a0..bf
	8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, // c0..df
	0xa,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x4,0x3,0x3, // e0..ef
	0xb,0x6,0x6,0x6,0x5,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8, // f0..ff
	0x0,0x1,0x2,0x3,0x5,0x8,0x7,0x1,0x1,0x1,0x4,0x6,0x1,0x1,0x1,0x1, // s0..s0
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1, // s1..s2
	1,2,1,1,1,1,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1, // s3..s4
	1,2,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,3,1,1,1,1,1,1, // s5..s6
	1,3,1,1,1,1,1,3,1,3,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1, // s7..s8
};


static inline uint32_t utf8_decode(uint32_t *state, uint32_t *codePoint, uint8_t byte)
{
    uint32_t type = utf8d[byte];
    *codePoint = (*state != UTF8_ACCEPT) ? ((byte & 0x3fu) | (*codePoint << 6)) :
    ((0xff >> type) & (byte));
    *state = utf8d[256 + ((*state) * 16) + type];
    return *state;
}


int utf8_isValid(const char *s)
{
	uint32_t codePoint = 0;
	uint32_t state = UTF8_ACCEPT;
	while (*s) { utf8_decode(&state, &codePoint, *s++); }
	return (state == UTF8_ACCEPT) ? true : false;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Print Code Points
// ------------------------------------------------------------------------------------------
void utf8_printCodePoints(const char *s)
{
	uint32_t codePoint = 0;
	uint32_t state = UTF8_ACCEPT;

	while (*s != '\0') {
		if (utf8_decode(&state, &codePoint, *s) == UTF8_ACCEPT) {
			printf("U+%04X ", codePoint);
		}
		s += 1;		
	}

	if (state != UTF8_ACCEPT) { printf("The string is not well-formed\n"); }
    else { printf("\n"); }
}


void utf8_printUTF16CodePoints(const char *s)
{
	uint32_t codePoint = 0;
	uint32_t state = UTF8_ACCEPT;
	
	for (; *s != '\0'; s++) {

		if (utf8_decode(&state, &codePoint, *s)) {
			continue;
		}

		if (codePoint <= 0xFFFF) {
			printf("0x%04X ", codePoint);
			continue;
		}

		// Encode code points above U+FFFF as surrogate pair.
		printf("0x%04X ", (0xD7C0 + (codePoint >> 10)));
		printf("0x%04X ", (0xDC00 + (codePoint & 0x3FF)));
	}
	
	if (state != UTF8_ACCEPT) {
		printf("The string is not well-formed\n");
	} else { printf("\n"); }
}


// ------------------------------------------------------------------------------------------
#pragma mark - Range
// ------------------------------------------------------------------------------------------
static inline size_t range_sum(GNERange range)
{
    return range.location + range.length;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Public
// ------------------------------------------------------------------------------------------
int GNEUnicodeTokenizeString(const char *cString, process_token process, void *context)
{
    if (process == NULL) { return failure; }

    GNERange range = {0, 0};

    uint32_t codePoint = 0;
    uint32_t state = UTF8_ACCEPT;

    size_t tokenCapacity = 1024; // TODO: Make this smaller initially and adjust it.
    size_t tokenLength = 0;
    uint32_t *token = calloc(tokenCapacity, sizeof(uint32_t));
    if (token == NULL) { return failure; }

    while (cString[range_sum(range)] != '\0') {
        if (utf8_decode(&state, &codePoint, cString[range_sum(range)]) == UTF8_ACCEPT) {
            // TODO: Handle invalid control characters.

            if (utf8_isBreak(codePoint) == true) {
                if (tokenLength > 0) {
                    GNERange tokenRange = {0, 0};
                    process(cString, tokenRange, token, tokenLength, context);
                }

                range.location = range_sum(range) + 1;
                range.length = 0;
                tokenLength = 0;
            } else {
                token[tokenLength] = codePoint;
                tokenLength += 1;
                range.length += 1;

                // TODO: Increase capacity of token, if needed.
            }


        } else { range.length += 1; }
    }

    if (tokenLength > 0) {
        GNERange tokenRange = {0, 0};
        process(cString, tokenRange, token, tokenLength, context);
    }

    free(token);

    return success;
}


int  GNEUnicodeCopyCodePoints(const char *cString, uint32_t **outCodePoints, size_t *outLength)
{
	if (outCodePoints == NULL || outLength == NULL) { return failure; }
	*outCodePoints = NULL;
	*outLength = 0;
	
	size_t size = sizeof(uint32_t);
	
	uint32_t codePoint = 0;
	uint32_t state = UTF8_ACCEPT;
	
	size_t capacity = 10;
	size_t length = 0;
	uint32_t *codePoints = calloc(capacity, size);
	if (codePoints == NULL) { return failure; }
	
	while (length < SIZE_MAX && *cString != '\0') {
		if (utf8_decode(&state, &codePoint, *cString) == UTF8_ACCEPT) {
			codePoints[length] = codePoint;
			length += 1;
			
			if (length == capacity) {
                size_t bufferLength = _tsearch_next_buf_len(&capacity, size);
				uint32_t *newCodePoints = realloc(codePoints, bufferLength);
				if (newCodePoints == NULL) { free(codePoints); return failure; }
				codePoints = newCodePoints;
			}
		}
		cString += 1;
	}
	
	if (state != UTF8_ACCEPT) { return failure; }

	*outCodePoints = codePoints;
	*outLength = length;
	return success;
}


result GNEUnicodeCopyUTF16CodePoints(const char *cString, uint32_t **outCodePoints, size_t *outLength)
{
	if (outCodePoints == NULL || outLength == NULL) { return failure; }
	*outCodePoints = NULL;
	*outLength = 0;
	
	size_t size = sizeof(uint32_t);
	
	uint32_t codePoint = 0;
	uint32_t state = UTF8_ACCEPT;
	
	size_t capacity = 10;
	size_t length = 0;
	uint32_t *codePoints = calloc(capacity, size);
	if (codePoints == NULL) { return failure; }
	
	uint32_t currentCodePoint[2] = {0, 0};
	size_t currentLength = 0;
	
	for (; length < SIZE_MAX && *cString != '\0'; cString++) {

		if (utf8_decode(&state, &codePoint, *cString) != UTF8_ACCEPT) { continue; }

		if (codePoint <= 0xFFFF) {
			currentCodePoint[0] = codePoint;
			currentLength = 1;
		} else {
			currentCodePoint[0] = 0xD7C0 + (codePoint >> 10);
			currentCodePoint[1] = 0xDC00 + (codePoint & 0x3FF);
			currentLength = 2;
		}
		
		for (size_t i = 0; i < currentLength; i++) {
			codePoints[length] = currentCodePoint[i];
			length += 1;
		}
		
		if (length >= capacity - 1) {
            size_t bufferLength = _tsearch_next_buf_len(&capacity, size);
			uint32_t *newCodePoints = realloc(codePoints, bufferLength);
			if (newCodePoints == NULL) { free(codePoints); return failure; }
			codePoints = newCodePoints;
		}
	}
	
	*outCodePoints = codePoints;
	*outLength = length;
	return success;
}


// http://www.unicode.org/versions/Unicode8.0.0/ch03.pdf
// Table 3-7. Well-Formed UTF-8 Byte Sequences
size_t GNEUnicodeNumberOfCharactersForCodePoint(uint32_t codePoint)
{
    if (codePoint <= 0x007F) { return 1; }
    if (codePoint <= 0x07FF) { return 2; }
    if (codePoint >= 0x0800 && codePoint <= 0xD7FF) { return 3; }
    if (codePoint >= 0xE000 && codePoint <= 0xFFFF) { return 3; }
    if (codePoint >= 0x10000 && codePoint <= 0x10FFFF) { return 4; }
    assert(0); // This should never be reached.
    return 0;
}
