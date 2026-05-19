//
//  GNETextSearchPrivate.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/14/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef GNETextSearchPrivate_h
#define GNETextSearchPrivate_h

#include <GNETextSearch/Types.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef TSEARCH_INLINE
    #if defined(_MSC_VER) && !defined(__cplusplus)
        #define TSEARCH_INLINE __inline
    #else
        #define TSEARCH_INLINE static inline
    #endif
#endif

TSEARCH_INLINE bool _tsearch_size_add_overflows(size_t a, size_t b, size_t *out)
{
    if (out == NULL) { return true; }
    if (a > SIZE_MAX - b) {
        *out = 0;
        return true;
    }

    *out = a + b;
    return false;
}


TSEARCH_INLINE bool _tsearch_size_mul_overflows(size_t a, size_t b, size_t *out)
{
    if (out == NULL) { return true; }
    if (a != 0 && b > SIZE_MAX / a) {
        *out = 0;
        return true;
    }

    *out = a * b;
    return false;
}


TSEARCH_INLINE result _tsearch_next_buf_len(size_t *capacity,
                                            const size_t elementSize,
                                            size_t *outByteLength)
{
    if (capacity == NULL || outByteLength == NULL || elementSize == 0) { return failure; }

    size_t count = *capacity;
    size_t half = count / 2;
    size_t nextCount = 0;
    if (_tsearch_size_add_overflows(count, half, &nextCount) || nextCount <= count) {
        return failure;
    }

    size_t byteLength = 0;
    if (_tsearch_size_mul_overflows(nextCount, elementSize, &byteLength)) {
        return failure;
    }

    *capacity = nextCount;
    *outByteLength = byteLength;
    return success;
}

#ifdef __cplusplus
}
#endif

#endif /* GNETextSearchPrivate_h */
