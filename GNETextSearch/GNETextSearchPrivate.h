//
//  GNETextSearchPrivate.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/14/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef GNETextSearchPrivate_h
#define GNETextSearchPrivate_h

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

TSEARCH_INLINE size_t _tsearch_next_buf_len(size_t *capacity, const size_t size)
{
    if (capacity == NULL) { return 0; }
    size_t count = *capacity;
    size_t nextCount = (count * 3) / 2;
    size_t validCount = (nextCount > count && ((SIZE_MAX / size) > nextCount)) ? nextCount : count;
    *capacity = validCount;
    return validCount * size;
}

#ifdef __cplusplus
}
#endif

#endif /* GNETextSearchPrivate_h */
