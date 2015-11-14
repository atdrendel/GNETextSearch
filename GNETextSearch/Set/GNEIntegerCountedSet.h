//
//  GNEIntegerCountedSet.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/14/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef GNEIntegerCountedSet_h
#define GNEIntegerCountedSet_h

#include <stdint.h>
#include "GNEIntegerArray.h"

typedef struct GNEIntegerCountedSet * GNEIntegerCountedSetPtr;

extern GNEIntegerCountedSetPtr GNEIntegerCountedSetCreate(void);
extern GNEIntegerCountedSetPtr GNEIntegerCountedSetCreateWithInteger(GNEInteger integer);
extern void GNEIntegerCountedSetDestroy(GNEIntegerCountedSetPtr ptr);

/// Returns 1 if the counted set includes the integer, otherwise 0.
extern int GNEIntegerCountedSetContainsInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer);

/// Returns the count for the specified integer. Returns 0 if the integer is not in the set.
extern size_t GNEIntegerCountedSetCountForInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer);

/// Adds the specified integer to the counted set. Returns 1 if successful, otherwise 0.
extern int GNEIntegerCountedSetAddInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer);


#endif /* GNEIntegerCountedSet_h */
