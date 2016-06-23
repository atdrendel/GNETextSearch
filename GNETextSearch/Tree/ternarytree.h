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
void tsearch_ternarytree_free(tsearch_ternarytree_ptr ptr);
tsearch_ternarytree_ptr tsearch_ternarytree_insert(tsearch_ternarytree_ptr ptr, const char *newCharacter, GNEInteger documentID);
result tsearch_ternarytree_remove(tsearch_ternarytree_ptr ptr, GNEInteger documentID);

/// Returns a GNEIntegerCountedSet with the IDs of the documents containing the target. The caller is
/// responsible for calling tsearch_countedset_free().
tsearch_countedset_ptr tsearch_ternarytree_copy_search_results(tsearch_ternarytree_ptr ptr, const char *target);

/// Returns a tsearch_countedset_ptr with the IDs of the documents containing the target prefix. The caller
/// is responsible for calling tsearch_countedset_free().
tsearch_countedset_ptr tsearch_ternarytree_copy_prefix_search_results(tsearch_ternarytree_ptr ptr, const char *prefix);

/// Copies all words contained in the tree into outResults (which much be freed by the caller).
result tsearch_ternarytree_copy_contents(tsearch_ternarytree_ptr ptr, char **outResults, size_t *outLength);

void tsearch_ternarytree_print(tsearch_ternarytree_ptr ptr);

#ifdef __cplusplus
}
#endif

#endif
