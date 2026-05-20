//
//  tokenize.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 1/2/16.
//  Copyright © 2016 Gone East LLC. All rights reserved.
//

#ifndef GNEUnicodeUtilities_h
#define GNEUnicodeUtilities_h

#include <GNETextSearch/Types.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {size_t location; size_t length;} tsearch_range;
typedef void(*process_token_func)(const char *string, const tsearch_range range, uint32_t *token,
                                  const size_t length, const void *context);

/// Tokenizes a non-NULL null-terminated UTF-8 string. The callback receives byte ranges in the
/// original string. Returns failure for NULL input, NULL callbacks, malformed UTF-8, or allocation failure.
result tsearch_cstring_tokenize(const char *cString, process_token_func process, void *context);

/// Copies UTF-8 code points from cString. On failure, writes NULL and 0.
result tsearch_cstring_copy_code_points(const char *cString, uint32_t **outCodePoints, size_t *outLength);

/// Copies UTF-16 code points represented as uint32_t values. On failure, writes NULL and 0.
result tsearch_cstring_copy_utf16_code_points(const char *cString, uint32_t **outCodePoints, size_t *outLength);
size_t tsearch_code_point_character_count(uint32_t codePoint);

#ifdef __cplusplus
}
#endif

#endif /* GNEUnicodeUtilities_h */
