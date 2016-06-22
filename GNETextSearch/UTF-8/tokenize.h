//
//  tokenize.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 1/2/16.
//  Copyright © 2016 Gone East LLC. All rights reserved.
//

#ifndef GNEUnicodeUtilities_h
#define GNEUnicodeUtilities_h

#include "GNETextSearchPublic.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {size_t location; size_t length;} tsearch_range;
typedef void(*process_token_func)(const char *string, tsearch_range range, uint32_t *token, size_t length, void *context);

extern result tsearch_cstring_tokenize(const char *cString, process_token_func process, void *context);

extern result tsearch_cstring_copy_code_points(const char *cString, uint32_t **outCodePoints, size_t *outLength);
extern result tsearch_cstring_copy_utf16_code_points(const char *cString, uint32_t **outCodePoints, size_t *outLength);
extern size_t tsearch_code_point_character_count(uint32_t codePoint);

#ifdef __cplusplus
}
#endif

#endif /* GNEUnicodeUtilities_h */
