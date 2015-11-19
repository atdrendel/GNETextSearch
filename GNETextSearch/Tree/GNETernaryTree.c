//
//  GNETernaryTree.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "GNETernaryTree.h"
#include "GNEMutableString.h"
#include "GNETextSearchPrivate.h"
#include <stdio.h>

// ------------------------------------------------------------------------------------------

GNETernaryTreePtr _GNETernaryTreeSearch(GNETernaryTreePtr ptr, const char *target);
int _GNETernaryTreeSearchFromNode(GNETernaryTreePtr ptr, GNEIntegerCountedSetPtr results);
int _GNETernaryTreeCopyContents(GNETernaryTreePtr ptr, GNEMutableStringPtr contentsPtr);
int _GNETernaryTreeCopyWord(GNETernaryTreePtr ptr, GNEMutableStringPtr contentsPtr);
int _GNETernaryTreeIsLeaf(GNETernaryTreePtr ptr);
size_t _GNETernaryTreeGetWordLength(GNETernaryTreePtr ptr);
int _GNETernaryTreeIncreaseCharBuffer(char **outBuffer, size_t *outBufferLength, size_t amount);

// ------------------------------------------------------------------------------------------
#pragma mark - Tree
// ------------------------------------------------------------------------------------------
typedef struct GNETernaryTreeNode
{
    char character;
    GNETernaryTreePtr parent;
    GNETernaryTreePtr lower, same, higher;
    GNEIntegerCountedSetPtr documentIDs;
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
        GNEIntegerCountedSetDestroy(ptr->documentIDs);
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
            if (ptr->documentIDs == NULL) { ptr->documentIDs = GNEIntegerCountedSetCreate(); }
            GNEIntegerCountedSetAddInteger(ptr->documentIDs, documentID);
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


GNEIntegerCountedSetPtr GNETernaryTreeSearch(GNETernaryTreePtr ptr, const char *target)
{
    GNETernaryTreePtr foundPtr = _GNETernaryTreeSearch(ptr, target);
    return (foundPtr != NULL) ? foundPtr->documentIDs : NULL;
}


GNEIntegerCountedSetPtr GNETernaryTreeSearchWithPrefix(GNETernaryTreePtr ptr, const char *prefix)
{
    GNETernaryTreePtr foundPtr = _GNETernaryTreeSearch(ptr, prefix);

    if (foundPtr == NULL) { return NULL; }

    GNEIntegerCountedSetPtr resultsPtr = GNEIntegerCountedSetCreate();

    if (resultsPtr == NULL) { return NULL; }

    if (foundPtr->documentIDs) {
        GNEIntegerCountedSetUnionSet(resultsPtr, foundPtr->documentIDs);
    }

    if (_GNETernaryTreeSearchFromNode(foundPtr->same, resultsPtr) == FAILURE) { return NULL; }

    if (GNEIntegerCountedSetGetCount(resultsPtr) == 0) {
        GNEIntegerCountedSetDestroy(resultsPtr);
        resultsPtr = NULL;
    }

    return resultsPtr;
}


int GNETernaryTreeCopyContents(GNETernaryTreePtr ptr, char **outResults, size_t *outLength)
{
    if (ptr == NULL || outResults == NULL || outLength == NULL) { return FAILURE; }

    GNEMutableStringPtr contentsPtr = GNEMutableStringCreate();

    int ret = _GNETernaryTreeCopyContents(ptr, contentsPtr);
    if (ret == SUCCESS) {
        *outResults = (char *)GNEMutableStringCopyContents(contentsPtr);
        *outLength = GNEMutableStringGetLength(contentsPtr);
    } else { *outLength = 0; }

    GNEMutableStringDestroy(contentsPtr);

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


int _GNETernaryTreeSearchFromNode(GNETernaryTreePtr ptr, GNEIntegerCountedSetPtr results)
{
    if (ptr == NULL) { return SUCCESS; }

    if (_GNETernaryTreeSearchFromNode(ptr->lower, results) == FAILURE) { return FAILURE; }
    if (_GNETernaryTreeSearchFromNode(ptr->same, results) == FAILURE) { return FAILURE; }

    if (ptr->documentIDs != NULL) {
        if (GNEIntegerCountedSetUnionSet(results, ptr->documentIDs) == FAILURE) { return FAILURE; }
    }

    return _GNETernaryTreeSearchFromNode(ptr->higher, results);
}


int _GNETernaryTreeCopyContents(GNETernaryTreePtr ptr, GNEMutableStringPtr contentsPtr)
{
    if (contentsPtr == NULL) { return FAILURE; }

    if (ptr == NULL) { return SUCCESS; }

    // We've found the end of a word. Append it to the results array.
    if (ptr->documentIDs != NULL) {
        if (_GNETernaryTreeCopyWord(ptr, contentsPtr) == FAILURE) { return FAILURE; }
    }

    // First, go down the left branches of the tree.
    if (_GNETernaryTreeCopyContents(ptr->lower, contentsPtr) == FAILURE) {
        return FAILURE;
    }

    // Proceed down the middle path to discover entries.
    if (_GNETernaryTreeCopyContents(ptr->same, contentsPtr) == FAILURE) {
        return FAILURE;
    }

    // Last, go down the right branches of the tree.
    return _GNETernaryTreeCopyContents(ptr->higher, contentsPtr);
}


int _GNETernaryTreeCopyWord(GNETernaryTreePtr ptr, GNEMutableStringPtr contentsPtr)
{
    if (ptr == NULL) { return SUCCESS; }

    size_t wordLength = _GNETernaryTreeGetWordLength(ptr) + 1; // Add one for the newline.
    if (wordLength == 1) { return SUCCESS; }
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

    int ret = GNEMutableStringAppendCString(contentsPtr, word, wordLength);
    free((void *)word);

    return ret;
}


/// Returns TRUE if the specified pointer is a leaf node (i.e., its lower, same, and
/// higher pointers are NULL), otherwise FALSE.
int _GNETernaryTreeIsLeaf(GNETernaryTreePtr ptr)
{
    if (ptr != NULL && ptr->lower == NULL && ptr->same == NULL && ptr->higher == NULL)
    {
        return TRUE;
    }
    return FALSE;
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


/// Increases the specified char buffer (of the specified length) by the specified amount.
/// Returns SUCCESS if the realloc operation succeed, otherwise FAILURE. In case of failure,
/// the outBuffer is freed.
int _GNETernaryTreeIncreaseCharBuffer(char **outBuffer, size_t *outBufferLength, size_t amount)
{
    if (amount == 0)
    {
        return SUCCESS;
    }

    if (outBuffer == NULL || (*outBuffer) == NULL || outBufferLength == NULL)
    {
        if (outBuffer && *outBuffer) { free((*outBuffer)); *outBuffer = NULL; }
        if (outBufferLength) { *outBufferLength = 0; }
        
        return FAILURE;
    }

    char *buffer = *outBuffer;
    size_t bufferLength = *outBufferLength;

    // Fail if the resulting buffer length is too large.
    if ((SIZE_MAX - (amount * sizeof(char))) < bufferLength)
    {
        free(buffer);
        *outBuffer = NULL;
        if (outBufferLength) { *outBufferLength = 0; }

        return FAILURE;
    }

    bufferLength = bufferLength + amount;
    char *newBuffer = realloc(buffer, sizeof(char) * bufferLength);
    if (newBuffer == NULL)
    {
        free(buffer);
        *outBuffer = NULL;
        if (outBufferLength) { *outBufferLength = 0; }

        return FAILURE;
    }

    *outBuffer = newBuffer;
    *outBufferLength = bufferLength;
    
    return SUCCESS;
}
