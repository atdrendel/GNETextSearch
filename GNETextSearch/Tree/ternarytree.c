//
//  ternarytree.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "ternarytree.h"
#include "stringbuf.h"
#include "GNETextSearchPrivate.h"
#include <stdio.h>

// ------------------------------------------------------------------------------------------

tsearch_ternarytree_ptr _tsearch_ternarytree_search(tsearch_ternarytree_ptr ptr, const char *target);
result _tsearch_ternarytree_search_from_node(tsearch_ternarytree_ptr ptr, tsearch_countedset_ptr results);
result _tsearch_ternarytree_copy_contents(tsearch_ternarytree_ptr ptr, tsearch_stringbuf_ptr contentsPtr);
result _tsearch_ternarytree_copy_word(tsearch_ternarytree_ptr ptr, tsearch_stringbuf_ptr contentsPtr);
result _tsearch_ternarytree_is_leaf(tsearch_ternarytree_ptr ptr);
size_t _tsearch_ternarytree_get_word_len(tsearch_ternarytree_ptr ptr);
result _tsearch_ternarytree_has_valid_document_ids(tsearch_ternarytree_ptr ptr);

// ------------------------------------------------------------------------------------------
#pragma mark - Tree
// ------------------------------------------------------------------------------------------
typedef struct tsearch_ternarytree_node
{
    char character;
    tsearch_ternarytree_ptr parent;
    tsearch_ternarytree_ptr lower, same, higher;
    tsearch_countedset_ptr documentIDs;
} tsearch_ternarytree_node;


tsearch_ternarytree_ptr tsearch_ternarytree_init(void)
{
    tsearch_ternarytree_ptr ptr = calloc(1, sizeof(tsearch_ternarytree_node));
    if (ptr == NULL) { return ptr; }

    ptr->character = '\0';
    ptr->parent = NULL;
    ptr->lower = NULL;
    ptr->same = NULL;
    ptr->higher = NULL;
    ptr->documentIDs = NULL;

    return ptr;
}


void tsearch_ternarytree_free(tsearch_ternarytree_ptr ptr)
{
    if (ptr != NULL) {
        ptr->parent = NULL;
        tsearch_ternarytree_free(ptr->lower);
        tsearch_ternarytree_free(ptr->same);
        tsearch_ternarytree_free(ptr->higher);
        tsearch_countedset_free(ptr->documentIDs);
        ptr->documentIDs = NULL;
        free(ptr);
    }
}


tsearch_ternarytree_ptr tsearch_ternarytree_insert(tsearch_ternarytree_ptr ptr, const char *newCharacter, GNEInteger documentID)
{
    if (newCharacter == NULL) { return ptr; }

    if (ptr == NULL) {
        ptr = tsearch_ternarytree_init();
        if (ptr == NULL) { return ptr; }
    }

    if (ptr->character == '\0') { ptr->character = *newCharacter; } // tsearch_ternarytree_init()

    if (*newCharacter < ptr->character) {
        ptr->lower = tsearch_ternarytree_insert(ptr->lower, newCharacter, documentID);
        ptr->lower->parent = ptr;
    } else if (*newCharacter == ptr->character) {
        if ('\0' == *(newCharacter + 1)) {
            if (ptr->documentIDs == NULL) { ptr->documentIDs = tsearch_countedset_init(); }
            tsearch_countedset_add_int(ptr->documentIDs, documentID);
        } else {
            ptr->same = tsearch_ternarytree_insert(ptr->same, (newCharacter + 1), documentID);
            ptr->same->parent = ptr;
        }
    } else {
        ptr->higher = tsearch_ternarytree_insert(ptr->higher, newCharacter, documentID);
        ptr->higher->parent = ptr;
    }

    return ptr;
}


result tsearch_ternarytree_remove(tsearch_ternarytree_ptr ptr, GNEInteger documentID)
{
    if (ptr == NULL) { return success; }

    if (_tsearch_ternarytree_has_valid_document_ids(ptr) == true) {
        if (tsearch_countedset_remove_int(ptr->documentIDs, documentID) == failure) {
            return failure;
        }
    }

    if (tsearch_ternarytree_remove(ptr->lower, documentID) == failure) { return failure; }
    if (tsearch_ternarytree_remove(ptr->same, documentID) == failure) { return failure; }
    return tsearch_ternarytree_remove(ptr->higher, documentID);
}


tsearch_countedset_ptr tsearch_ternarytree_copy_search_results(tsearch_ternarytree_ptr ptr, const char *target)
{
    tsearch_ternarytree_ptr foundPtr = _tsearch_ternarytree_search(ptr, target);
    int hasResults = _tsearch_ternarytree_has_valid_document_ids(foundPtr);
    return (hasResults == true) ? tsearch_countedset_copy(foundPtr->documentIDs) : NULL;
}


tsearch_countedset_ptr tsearch_ternarytree_copy_prefix_search_results(tsearch_ternarytree_ptr ptr, const char *prefix)
{
    tsearch_ternarytree_ptr foundPtr = _tsearch_ternarytree_search(ptr, prefix);

    if (foundPtr == NULL) { return NULL; }

    tsearch_countedset_ptr resultsPtr = tsearch_countedset_init();

    if (resultsPtr == NULL) { return NULL; }

    if (_tsearch_ternarytree_has_valid_document_ids(foundPtr) == true) {
        tsearch_countedset_union(resultsPtr, foundPtr->documentIDs);
    }

    if (_tsearch_ternarytree_search_from_node(foundPtr->same, resultsPtr) == failure) {
        tsearch_countedset_free(resultsPtr);
        return NULL;
    }

    if (tsearch_countedset_get_count(resultsPtr) == 0) {
        tsearch_countedset_free(resultsPtr);
        resultsPtr = NULL;
    }

    return resultsPtr;
}


result tsearch_ternarytree_copy_contents(tsearch_ternarytree_ptr ptr, char **outResults, size_t *outLength)
{
    if (ptr == NULL || outResults == NULL || outLength == NULL) { return failure; }

    tsearch_stringbuf_ptr contentsPtr = tsearch_stringbuf_init();

    int ret = _tsearch_ternarytree_copy_contents(ptr, contentsPtr);
    if (ret == success) {
        *outResults = (char *)tsearch_stringbuf_copy_cstring(contentsPtr);
        *outLength = tsearch_stringbuf_get_len(contentsPtr);
    } else { *outLength = 0; }

    tsearch_stringbuf_free(contentsPtr);

    return ret;
}


void tsearch_ternarytree_print(tsearch_ternarytree_ptr ptr)
{
    char *results = NULL;
    size_t length = 0;

    tsearch_ternarytree_copy_contents(ptr, &results, &length);

    printf("<GNETernaryTree, %p>\n", ptr);
    printf("%s", results);
    printf("\n");

    free(results);
    results = NULL;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
tsearch_ternarytree_ptr _tsearch_ternarytree_search(tsearch_ternarytree_ptr ptr, const char *target)
{
    if (ptr == NULL) { return NULL; }

    const char targetCharacter = *target;

    if (targetCharacter != '\0' && targetCharacter < ptr->character) {
        return _tsearch_ternarytree_search(ptr->lower, target);
    } else if (targetCharacter != '\0' && targetCharacter > ptr->character) {
        return _tsearch_ternarytree_search(ptr->higher, target);
    } else {
        if (*(target + 1) == '\0') { return ptr; }
        else { return _tsearch_ternarytree_search(ptr->same, ++target); }
    }
}


result _tsearch_ternarytree_search_from_node(tsearch_ternarytree_ptr ptr, tsearch_countedset_ptr results)
{
    if (ptr == NULL) { return success; }

    if (_tsearch_ternarytree_has_valid_document_ids(ptr) == true) {
        if (tsearch_countedset_union(results, ptr->documentIDs) == failure) { return failure; }
    }

    if (_tsearch_ternarytree_search_from_node(ptr->lower, results) == failure) { return failure; }
    if (_tsearch_ternarytree_search_from_node(ptr->same, results) == failure) { return failure; }
    return _tsearch_ternarytree_search_from_node(ptr->higher, results);
}


result _tsearch_ternarytree_copy_contents(tsearch_ternarytree_ptr ptr, tsearch_stringbuf_ptr contentsPtr)
{
    if (contentsPtr == NULL) { return failure; }
    if (ptr == NULL) { return success; }

    // We've found the end of a word. Append it to the results array.
    if (_tsearch_ternarytree_has_valid_document_ids(ptr) == true) {
        if (_tsearch_ternarytree_copy_word(ptr, contentsPtr) == failure) { return failure; }
    }

    if (_tsearch_ternarytree_copy_contents(ptr->lower, contentsPtr) == failure) { return failure; }
    if (_tsearch_ternarytree_copy_contents(ptr->same, contentsPtr) == failure) { return failure; }
    return _tsearch_ternarytree_copy_contents(ptr->higher, contentsPtr);
}


result _tsearch_ternarytree_copy_word(tsearch_ternarytree_ptr ptr, tsearch_stringbuf_ptr contentsPtr)
{
    if (ptr == NULL) { return success; }

    size_t wordLength = _tsearch_ternarytree_get_word_len(ptr) + 1; // Add one for the newline.
    if (wordLength == 1) { return success; }
    char *word = calloc((wordLength), sizeof(char));

    size_t characterIndex = wordLength - 1;
    word[characterIndex] = '\n';
    characterIndex -= 1;

    word[characterIndex] = ptr->character;
    characterIndex -= 1;

    while (ptr != NULL) {
        if (ptr->parent != NULL && ptr->parent->same == ptr) {
            word[characterIndex] = ptr->parent->character;
            if (characterIndex == 0) { break; }
            characterIndex -= 1;
        }

        ptr = ptr->parent;
    }

    int ret = tsearch_stringbuf_append_cstring(contentsPtr, word, wordLength);
    free((void *)word);

    return ret;
}


/// Returns true if the specified pointer is a leaf node (i.e., its lower, same, and
/// higher pointers are NULL), otherwise false.
result _tsearch_ternarytree_is_leaf(tsearch_ternarytree_ptr ptr)
{
    if (ptr != NULL && ptr->lower == NULL && ptr->same == NULL && ptr->higher == NULL)
    {
        return true;
    }
    return false;
}


/// Returns the length of the beginning at the specified pointer.
/// The length does NOT include the trailing null terminator.
size_t _tsearch_ternarytree_get_word_len(tsearch_ternarytree_ptr ptr)
{
    if (ptr == NULL || ptr->documentIDs == NULL) { return 0; }

    size_t length = 1;

    while (ptr != NULL) {
        if (ptr->parent != NULL && ptr->parent->same == ptr) {
            length = length + 1;
        }
        ptr = ptr->parent;
    }

    return length;
}


/// Return true if the specified node contains one or more document IDs, otherwise false;
result _tsearch_ternarytree_has_valid_document_ids(tsearch_ternarytree_ptr ptr)
{
    if (ptr == NULL || ptr->documentIDs == NULL) { return false; }
    return (tsearch_countedset_get_count(ptr->documentIDs) > 0) ? true : false;
}
