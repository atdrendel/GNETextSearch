//
//  ternarytree.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef GNETernaryTree_h
#define GNETernaryTree_h

#include "countedset.h"
#include "GNETextSearchPublic.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct tsearch_ternarytree_node *tsearch_ternarytree_ptr;

tsearch_ternarytree_ptr tsearch_ternarytree_init(void);
void tsearch_ternarytree_free(const tsearch_ternarytree_ptr ptr);
tsearch_ternarytree_ptr tsearch_ternarytree_insert(tsearch_ternarytree_ptr ptr,
                                                   const char *newCharacter, const GNEInteger documentID);
result tsearch_ternarytree_remove(const tsearch_ternarytree_ptr ptr, const GNEInteger documentID);

/// Returns a GNEIntegerCountedSet with the IDs of the documents containing the target. The caller is
/// responsible for calling tsearch_countedset_free().
tsearch_countedset_ptr tsearch_ternarytree_copy_search_results(const tsearch_ternarytree_ptr ptr, const char *target);

/// Returns a tsearch_countedset_ptr with the IDs of the documents containing the target prefix. The caller
/// is responsible for calling tsearch_countedset_free().
tsearch_countedset_ptr tsearch_ternarytree_copy_prefix_search_results(const tsearch_ternarytree_ptr ptr, const char *prefix);

/// Returns a tsearch_countedset_ptr with the IDs of the documents containing the target suffix. The caller
/// is responsible for calling tsearch_countedset_free().
tsearch_countedset_ptr tsearch_ternarytree_copy_suffix_search_results(const tsearch_ternarytree_ptr ptr,
                                                                      const char *suffix,
                                                                      const size_t length);

/// Copies all words contained in the tree into outResults (which much be freed by the caller).
result tsearch_ternarytree_copy_contents(const tsearch_ternarytree_ptr ptr, char **outResults, size_t *outLength);

void tsearch_ternarytree_print(const tsearch_ternarytree_ptr ptr);

#ifdef __cplusplus
}
#endif

#endif
