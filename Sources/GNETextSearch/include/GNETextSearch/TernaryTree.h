//
//  ternarytree.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef GNETernaryTree_h
#define GNETernaryTree_h

#include <GNETextSearch/CountedSet.h>
#include <GNETextSearch/Types.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct tsearch_ternarytree_node *tsearch_ternarytree_ptr;

/// Creates an empty ternary tree. The caller is responsible for calling tsearch_ternarytree_free().
tsearch_ternarytree_ptr tsearch_ternarytree_init(void);

/// Loads a tree previously written with tsearch_ternarytree_save_to_file().
/// The caller is responsible for calling tsearch_ternarytree_free().
/// Returns NULL for NULL paths, invalid files, unsupported file versions, or I/O errors.
tsearch_ternarytree_ptr tsearch_ternarytree_init_from_file(const char *path);

/// Loads a tree from bytes previously written with tsearch_ternarytree_copy_serialized_bytes().
/// The caller is responsible for calling tsearch_ternarytree_free().
/// Returns NULL for NULL bytes, zero lengths, invalid bytes, or unsupported serialization versions.
tsearch_ternarytree_ptr tsearch_ternarytree_init_from_serialized_bytes(const uint8_t *bytes, const size_t length);

/// Frees a ternary tree created by this API. NULL is allowed.
void tsearch_ternarytree_free(const tsearch_ternarytree_ptr ptr);

/// Copies the tree to a binary representation that can be loaded with tsearch_ternarytree_init_from_serialized_bytes().
/// On success, writes newly allocated bytes to outBytes and their length to outLength. The caller must free() outBytes.
/// On failure, writes NULL and 0. Returns failure for NULL trees, NULL outputs, or allocation failure.
result tsearch_ternarytree_copy_serialized_bytes(const tsearch_ternarytree_ptr ptr,
                                                uint8_t **outBytes,
                                                size_t *outLength);

/// Writes the tree to a binary file that can be loaded with tsearch_ternarytree_init_from_file().
/// Returns failure for NULL trees, NULL paths, or I/O errors.
result tsearch_ternarytree_save_to_file(const tsearch_ternarytree_ptr ptr, const char *path);

/// Inserts a non-empty null-terminated string. NULL and empty strings are ignored and return ptr.
/// Because the public API cannot report allocation failure, failed allocations leave the tree in
/// a valid state and return the current root pointer.
tsearch_ternarytree_ptr tsearch_ternarytree_insert(tsearch_ternarytree_ptr ptr,
                                                   const char *newCharacter, const GNEInteger documentID);

/// Removes the document ID from every word in the tree. Success is unrelated to whether the document ID exists.
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

/// Returns a tsearch_countedset_ptr with the IDs of documents containing a word where the target
/// appears as an ordered subsequence, which may be contiguous or non-contiguous. For example,
/// "ETxc" matches "GNETextSearch".
/// The caller is responsible for calling tsearch_countedset_free().
/// Returns NULL for NULL targets, a zero length, or no matches.
tsearch_countedset_ptr tsearch_ternarytree_copy_subsequence_search_results(const tsearch_ternarytree_ptr ptr,
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

/// Prints the tree's contents to stdout. NULL trees print an empty contents section.
void tsearch_ternarytree_print(const tsearch_ternarytree_ptr ptr);

#ifdef __cplusplus
}
#endif

#endif
