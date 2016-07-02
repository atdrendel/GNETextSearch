//
//  countedset.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/14/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef tsearch_countedset_h
#define tsearch_countedset_h

#include "GNETextSearchPublic.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct tsearch_countedset * tsearch_countedset_ptr;

tsearch_countedset_ptr tsearch_countedset_init(void);
tsearch_countedset_ptr tsearch_countedset_copy(const tsearch_countedset_ptr ptr);
void tsearch_countedset_free(const tsearch_countedset_ptr ptr);

size_t tsearch_countedset_get_count(tsearch_countedset_ptr ptr);

/// Returns 1 if the counted set includes the integer, otherwise 0.
bool tsearch_countedset_contains_int(const tsearch_countedset_ptr ptr, const GNEInteger integer);

/// Returns the count for the specified integer. Returns 0 if the integer is not in the set.
size_t tsearch_countedset_get_count_for_int(const tsearch_countedset_ptr ptr, const GNEInteger integer);

/// Creates an array of all of the integers in the specified counted set in descending order
/// (the integer with the largest count is returned first). On return, the specified outIntegers
/// pointer points at the array, which must be freed by the caller.
result tsearch_countedset_copy_ints(const tsearch_countedset_ptr ptr, GNEInteger **outIntegers, size_t *outCount);

/// Adds the specified integer to the counted set. Returns 1 if successful, otherwise 0.
result tsearch_countedset_add_int(const tsearch_countedset_ptr ptr, const GNEInteger integer);

/// Removes the specified integer from the counted set. Returns 1 if successful, otherwise 0.
/// Success is unrelated to whether or not the integer exists in the counted set.
result tsearch_countedset_remove_int(const tsearch_countedset_ptr ptr, const GNEInteger integer);

/// Removes all of the integers from the counted set.
result tsearch_countedset_remove_all_ints(const tsearch_countedset_ptr ptr);

/// Adds each integer and its count in the other counted set to specified set.
result tsearch_countedset_union(const tsearch_countedset_ptr ptr, const tsearch_countedset_ptr otherPtr);

/// Removes from the specified counted set each integer that isn’t a member of the other set.
/// If an integer is present in both sets, its counts are added together.
result tsearch_countedset_intersect(const tsearch_countedset_ptr ptr, const tsearch_countedset_ptr otherPtr);

/// Removes each integer in the other counted set from the specified set, if present.
result tsearch_countedset_minus(const tsearch_countedset_ptr ptr, const tsearch_countedset_ptr otherPtr);

#ifdef __cplusplus
}
#endif

#endif /* tsearch_countedset_h */
