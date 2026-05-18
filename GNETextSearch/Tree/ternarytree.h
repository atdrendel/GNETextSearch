//
//  ternarytree.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef GNETernaryTree_h
#define GNETernaryTree_h

#if defined(__has_include)
    #if __has_include(<GNETextSearch/countedset.h>)
        #include <GNETextSearch/countedset.h>
    #else
        #include "../Set/countedset.h"
    #endif
    #if __has_include(<GNETextSearch/GNETextSearchPublic.h>)
        #include <GNETextSearch/GNETextSearchPublic.h>
    #else
        #include "../GNETextSearchPublic.h"
    #endif
#else
    #include "../Set/countedset.h"
    #include "../GNETextSearchPublic.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct tsearch_ternarytree_node *tsearch_ternarytree_ptr;

tsearch_ternarytree_ptr tsearch_ternarytree_init(void);
void tsearch_ternarytree_free(const tsearch_ternarytree_ptr ptr);

/// Inserts a non-empty null-terminated string. NULL and empty strings are ignored and return ptr.
/// Because the public API cannot report allocation failure, failed allocations leave the tree in
/// a valid state and return the current root pointer.
tsearch_ternarytree_ptr tsearch_ternarytree_insert(tsearch_ternarytree_ptr ptr,
                                                   const char *newCharacter, const GNEInteger documentID);
result tsearch_ternarytree_remove(const tsearch_ternarytree_ptr ptr, const GNEInteger documentID);

/// Returns a GNEIntegerCountedSet with the IDs of the documents containing the target. The caller is
/// responsible for calling tsearch_countedset_free().
/// Returns NULL for NULL or empty target strings.
tsearch_countedset_ptr tsearch_ternarytree_copy_search_results(const tsearch_ternarytree_ptr ptr, const char *target);

/// Returns a tsearch_countedset_ptr with the IDs of the documents containing the target prefix. The caller
/// is responsible for calling tsearch_countedset_free().
/// Returns NULL for NULL or empty prefixes.
tsearch_countedset_ptr tsearch_ternarytree_copy_prefix_search_results(const tsearch_ternarytree_ptr ptr, const char *prefix);

/// Returns a tsearch_countedset_ptr with the IDs of the documents containing the target string. The caller
/// is responsible for calling tsearch_countedset_free().
/// Returns NULL for NULL targets or a zero length.
tsearch_countedset_ptr tsearch_ternarytree_copy_partial_search_results(const tsearch_ternarytree_ptr ptr,
                                                                       const char *target,
                                                                       const size_t length);

/// Returns a tsearch_countedset_ptr with the IDs of the documents containing the target suffix. The caller
/// is responsible for calling tsearch_countedset_free().
/// Returns NULL for NULL suffixes or a zero length.
tsearch_countedset_ptr tsearch_ternarytree_copy_suffix_search_results(const tsearch_ternarytree_ptr ptr,
                                                                      const char *suffix,
                                                                      const size_t length);

/// Copies all words contained in the tree into outResults (which must be freed by the caller).
/// On failure, writes NULL and 0.
result tsearch_ternarytree_copy_contents(const tsearch_ternarytree_ptr ptr, char **outResults, size_t *outLength);

void tsearch_ternarytree_print(const tsearch_ternarytree_ptr ptr);

#ifdef __cplusplus
}
#endif

#endif
