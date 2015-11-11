//
//  GNEIntegerArray.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 9/11/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef GNEIntegerArray_h
#define GNEIntegerArray_h

#include <stdint.h>

#ifndef GNEInteger
    #define GNEInteger int64_t
#endif

typedef struct GNEIntegerArray *GNEIntegerArrayPtr;

extern GNEIntegerArrayPtr GNEIntegerArrayCreate(void);
extern GNEIntegerArrayPtr GNEIntegerArrayCreateWithCapacity(size_t capacity);
extern void GNEIntegerArrayDestroy(GNEIntegerArrayPtr ptr);
extern size_t GNEIntegerArrayGetCount(GNEIntegerArrayPtr ptr);
extern int GNEIntegerArrayAddInteger(GNEIntegerArrayPtr ptr, GNEInteger integer);
extern int GNEIntegerArrayAddIntegersFromArray(GNEIntegerArrayPtr ptr, GNEIntegerArrayPtr otherPtr);

/// Returns the integer at the specified index or SIZE_MAX if the index is invalid.
extern GNEInteger GNEIntegerArrayGetIntegerAtIndex(GNEIntegerArrayPtr ptr, size_t index);

extern void GNEIntegerArrayPrint(GNEIntegerArrayPtr ptr);

#endif /* GNEIntegerArray_h */
