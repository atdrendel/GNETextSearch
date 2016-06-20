//
//  GNEUnicodeUtilities.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 1/2/16.
//  Copyright © 2016 Gone East LLC. All rights reserved.
//

#ifndef GNEUnicodeUtilities_h
#define GNEUnicodeUtilities_h

#include "GNETextSearchPublic.h"

typedef struct {size_t location; size_t length;} GNERange;
typedef void(*process_token_func)(const char *string, GNERange range, uint32_t *token, size_t length, void *context);

extern result GNEUnicodeTokenizeString(const char *cString, process_token_func process, void *context);

extern result GNEUnicodeCopyCodePoints(const char *cString, uint32_t **outCodePoints, size_t *outLength);
extern result GNEUnicodeCopyUTF16CodePoints(const char *cString, uint32_t **outCodePoints, size_t *outLength);
extern size_t GNEUnicodeNumberOfCharactersForCodePoint(uint32_t codePoint);

#endif /* GNEUnicodeUtilities_h */
