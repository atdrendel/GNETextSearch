//
//  GNETextSearchPrivate.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/14/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef GNETextSearchPrivate_h
#define GNETextSearchPrivate_h

// ------------------------------------------------------------------------------------------

#include <stdlib.h>

#define SUCCESS 1
#define FAILURE 0

#define TRUE 1
#define FALSE 0

static inline size_t GNENextCapacityForMultipleAndSize(const size_t capacity,
                                                       const size_t multiple,
                                                       const size_t size)
{
    const size_t kMaxSize = UINT32_MAX - 1;
    size_t maxCapacity = kMaxSize / size;
    size_t next = (capacity <= (maxCapacity / multiple)) ? capacity * multiple : maxCapacity;
    return next;
}

// ------------------------------------------------------------------------------------------

#endif /* GNETextSearchPrivate_h */
