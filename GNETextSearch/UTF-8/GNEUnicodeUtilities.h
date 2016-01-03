//
//  GNEUnicodeUtilities.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 1/2/16.
//  Copyright © 2016 Gone East LLC. All rights reserved.
//

#ifndef GNEUnicodeUtilities_h
#define GNEUnicodeUtilities_h

#include <stdlib.h>

typedef struct {size_t location; size_t length;} GNERange;
typedef void(*process_token)(const char *string, GNERange range, uint32_t *token, size_t length);

int GNEUnicodeTokenizeString(const char *cString, process_token process);

int GNEUnicodeCopyCodePoints(const char *cString, uint32_t **outCodePoints, size_t *outLength);
int GNEUnicodeCopyUTF16CodePoints(const char *cString, uint32_t **outCodePoints, size_t *outLength);
size_t GNEUnicodeNumberOfCharactersForCodePoint(uint32_t codePoint);

#endif /* GNEUnicodeUtilities_h */
