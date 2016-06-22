//
//  GNETernaryTree.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "GNETernaryTree.h"
#include "stringbuf.h"
#include "GNETextSearchPrivate.h"
#include <stdio.h>

// ------------------------------------------------------------------------------------------

GNETernaryTreePtr _GNETernaryTreeSearch(GNETernaryTreePtr ptr, const char *target);
result _GNETernaryTreeSearchFromNode(GNETernaryTreePtr ptr, tsearch_countedset_ptr results);
result _GNETernaryTreeCopyContents(GNETernaryTreePtr ptr, tsearch_stringbuf_ptr contentsPtr);
result _GNETernaryTreeCopyWord(GNETernaryTreePtr ptr, tsearch_stringbuf_ptr contentsPtr);
result _GNETernaryTreeIsLeaf(GNETernaryTreePtr ptr);
size_t _GNETernaryTreeGetWordLength(GNETernaryTreePtr ptr);
result _GNETernaryTreeHasValidDocumentIDs(GNETernaryTreePtr ptr);
result _GNETernaryTreeIncreaseCharBuffer(char **outBuffer, size_t *outBufferLength, size_t amount);

// ------------------------------------------------------------------------------------------
#pragma mark - Tree
// ------------------------------------------------------------------------------------------
typedef struct GNETernaryTreeNode
{
    char character;
    GNETernaryTreePtr parent;
    GNETernaryTreePtr lower, same, higher;
    tsearch_countedset_ptr documentIDs;
} GNETernaryTreeNode;


GNETernaryTreePtr GNETernaryTreeCreate(void)
{
    GNETernaryTreePtr ptr = calloc(1, sizeof(GNETernaryTreeNode));
    if (ptr == NULL) { return ptr; }

    ptr->character = '\0';
    ptr->parent = NULL;
    ptr->lower = NULL;
    ptr->same = NULL;
    ptr->higher = NULL;
    ptr->documentIDs = NULL;

    return ptr;
}


void GNETernaryTreeDestroy(GNETernaryTreePtr ptr)
{
    if (ptr != NULL) {
        ptr->parent = NULL;
        GNETernaryTreeDestroy(ptr->lower);
        GNETernaryTreeDestroy(ptr->same);
        GNETernaryTreeDestroy(ptr->higher);
        tsearch_countedset_free(ptr->documentIDs);
        ptr->documentIDs = NULL;
        free(ptr);
    }
}


GNETernaryTreePtr GNETernaryTreeInsert(GNETernaryTreePtr ptr, const char *newCharacter, GNEInteger documentID)
{
    if (newCharacter == NULL) { return ptr; }

    if (ptr == NULL) {
        ptr = GNETernaryTreeCreate();
        if (ptr == NULL) { return ptr; }
    }

    if (ptr->character == '\0') { ptr->character = *newCharacter; } // GNETernaryTreeCreate()

    if (*newCharacter < ptr->character) {
        ptr->lower = GNETernaryTreeInsert(ptr->lower, newCharacter, documentID);
        ptr->lower->parent = ptr;
    } else if (*newCharacter == ptr->character) {
        if ('\0' == *(newCharacter + 1)) {
            if (ptr->documentIDs == NULL) { ptr->documentIDs = tsearch_countedset_init(); }
            tsearch_countedset_add_int(ptr->documentIDs, documentID);
        } else {
            ptr->same = GNETernaryTreeInsert(ptr->same, (newCharacter + 1), documentID);
            ptr->same->parent = ptr;
        }
    } else {
        ptr->higher = GNETernaryTreeInsert(ptr->higher, newCharacter, documentID);
        ptr->higher->parent = ptr;
    }

    return ptr;
}


result GNETernaryTreeRemove(GNETernaryTreePtr ptr, GNEInteger documentID)
{
    if (ptr == NULL) { return success; }

    if (_GNETernaryTreeHasValidDocumentIDs(ptr) == true) {
        if (tsearch_countedset_remove_int(ptr->documentIDs, documentID) == failure) {
            return failure;
        }
    }

    if (GNETernaryTreeRemove(ptr->lower, documentID) == failure) { return failure; }
    if (GNETernaryTreeRemove(ptr->same, documentID) == failure) { return failure; }
    return GNETernaryTreeRemove(ptr->higher, documentID);
}


tsearch_countedset_ptr GNETernaryTreeCopyResultsForSearch(GNETernaryTreePtr ptr, const char *target)
{
    GNETernaryTreePtr foundPtr = _GNETernaryTreeSearch(ptr, target);
    int hasResults = _GNETernaryTreeHasValidDocumentIDs(foundPtr);
    return (hasResults == true) ? tsearch_countedset_copy(foundPtr->documentIDs) : NULL;
}


tsearch_countedset_ptr GNETernaryTreeCopyResultsForPrefixSearch(GNETernaryTreePtr ptr, const char *prefix)
{
    GNETernaryTreePtr foundPtr = _GNETernaryTreeSearch(ptr, prefix);

    if (foundPtr == NULL) { return NULL; }

    tsearch_countedset_ptr resultsPtr = tsearch_countedset_init();

    if (resultsPtr == NULL) { return NULL; }

    if (_GNETernaryTreeHasValidDocumentIDs(foundPtr) == true) {
        tsearch_countedset_union(resultsPtr, foundPtr->documentIDs);
    }

    if (_GNETernaryTreeSearchFromNode(foundPtr->same, resultsPtr) == failure) {
        tsearch_countedset_free(resultsPtr);
        return NULL;
    }

    if (tsearch_countedset_get_count(resultsPtr) == 0) {
        tsearch_countedset_free(resultsPtr);
        resultsPtr = NULL;
    }

    return resultsPtr;
}


result GNETernaryTreeCopyContents(GNETernaryTreePtr ptr, char **outResults, size_t *outLength)
{
    if (ptr == NULL || outResults == NULL || outLength == NULL) { return failure; }

    tsearch_stringbuf_ptr contentsPtr = tsearch_stringbuf_init();

    int ret = _GNETernaryTreeCopyContents(ptr, contentsPtr);
    if (ret == success) {
        *outResults = (char *)tsearch_stringbuf_copy_cstring(contentsPtr);
        *outLength = tsearch_stringbuf_get_len(contentsPtr);
    } else { *outLength = 0; }

    tsearch_stringbuf_free(contentsPtr);

    return ret;
}


void GNETernaryTreePrint(GNETernaryTreePtr ptr)
{
    char *results = NULL;
    size_t length = 0;

    GNETernaryTreeCopyContents(ptr, &results, &length);

    printf("<GNETernaryTree, %p>\n", ptr);
    printf("%s", results);
    printf("\n");

    free(results);
    results = NULL;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
GNETernaryTreePtr _GNETernaryTreeSearch(GNETernaryTreePtr ptr, const char *target)
{
    if (ptr == NULL) { return NULL; }

    const char targetCharacter = *target;

    if (targetCharacter != '\0' && targetCharacter < ptr->character) {
        return _GNETernaryTreeSearch(ptr->lower, target);
    } else if (targetCharacter != '\0' && targetCharacter > ptr->character) {
        return _GNETernaryTreeSearch(ptr->higher, target);
    } else {
        if (*(target + 1) == '\0') { return ptr; }
        else { return _GNETernaryTreeSearch(ptr->same, ++target); }
    }
}


result _GNETernaryTreeSearchFromNode(GNETernaryTreePtr ptr, tsearch_countedset_ptr results)
{
    if (ptr == NULL) { return success; }

    if (_GNETernaryTreeHasValidDocumentIDs(ptr) == true) {
        if (tsearch_countedset_union(results, ptr->documentIDs) == failure) { return failure; }
    }

    if (_GNETernaryTreeSearchFromNode(ptr->lower, results) == failure) { return failure; }
    if (_GNETernaryTreeSearchFromNode(ptr->same, results) == failure) { return failure; }
    return _GNETernaryTreeSearchFromNode(ptr->higher, results);
}


result _GNETernaryTreeCopyContents(GNETernaryTreePtr ptr, tsearch_stringbuf_ptr contentsPtr)
{
    if (contentsPtr == NULL) { return failure; }
    if (ptr == NULL) { return success; }

    // We've found the end of a word. Append it to the results array.
    if (_GNETernaryTreeHasValidDocumentIDs(ptr) == true) {
        if (_GNETernaryTreeCopyWord(ptr, contentsPtr) == failure) { return failure; }
    }

    if (_GNETernaryTreeCopyContents(ptr->lower, contentsPtr) == failure) { return failure; }
    if (_GNETernaryTreeCopyContents(ptr->same, contentsPtr) == failure) { return failure; }
    return _GNETernaryTreeCopyContents(ptr->higher, contentsPtr);
}


result _GNETernaryTreeCopyWord(GNETernaryTreePtr ptr, tsearch_stringbuf_ptr contentsPtr)
{
    if (ptr == NULL) { return success; }

    size_t wordLength = _GNETernaryTreeGetWordLength(ptr) + 1; // Add one for the newline.
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
result _GNETernaryTreeIsLeaf(GNETernaryTreePtr ptr)
{
    if (ptr != NULL && ptr->lower == NULL && ptr->same == NULL && ptr->higher == NULL)
    {
        return true;
    }
    return false;
}


/// Returns the length of the beginning at the specified pointer.
/// The length does NOT include the trailing null terminator.
size_t _GNETernaryTreeGetWordLength(GNETernaryTreePtr ptr)
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
result _GNETernaryTreeHasValidDocumentIDs(GNETernaryTreePtr ptr)
{
    if (ptr == NULL || ptr->documentIDs == NULL) { return false; }
    return (tsearch_countedset_get_count(ptr->documentIDs) > 0) ? true : false;
}


/// Increases the specified char buffer (of the specified length) by the specified amount.
/// Returns success if the realloc operation succeed, otherwise failure. In case of failure,
/// the outBuffer is freed.
result _GNETernaryTreeIncreaseCharBuffer(char **outBuffer, size_t *outBufferLength, size_t amount)
{
    if (amount == 0)
    {
        return success;
    }

    if (outBuffer == NULL || (*outBuffer) == NULL || outBufferLength == NULL)
    {
        if (outBuffer && *outBuffer) { free((*outBuffer)); *outBuffer = NULL; }
        if (outBufferLength) { *outBufferLength = 0; }

        return failure;
    }

    char *buffer = *outBuffer;
    size_t bufferLength = *outBufferLength;

    // Fail if the resulting buffer length is too large.
    if ((SIZE_MAX - (amount * sizeof(char))) < bufferLength)
    {
        free(buffer);
        *outBuffer = NULL;
        if (outBufferLength) { *outBufferLength = 0; }

        return failure;
    }

    bufferLength = bufferLength + amount;
    char *newBuffer = realloc(buffer, sizeof(char) * bufferLength);
    if (newBuffer == NULL)
    {
        free(buffer);
        *outBuffer = NULL;
        if (outBufferLength) { *outBufferLength = 0; }

        return failure;
    }

    *outBuffer = newBuffer;
    *outBufferLength = bufferLength;

    return success;
}
