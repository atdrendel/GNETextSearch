//
//  GNETernaryTree.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "GNETernaryTree.h"
#include <stdlib.h>
#include <stdio.h>


// ------------------------------------------------------------------------------------------


#define SUCCESS 1
#define FAILURE 0

#define TRUE 1
#define FALSE 0

GNETernaryTreePtr _GNETernaryTreeSearch(GNETernaryTreePtr ptr, const char *target);
int _GNETernaryTreeSearchFromNode(GNETernaryTreePtr ptr, GNEIntegerArrayPtr results);
int _GNETernaryTreeCopyContents(GNETernaryTreePtr ptr, char **outResults, size_t *outLength, size_t *outBufferLength);
int _GNETernaryTreeCopyWord(GNETernaryTreePtr ptr, char **outResults, size_t *outLength, size_t *outBufferLength);
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
    GNEIntegerArrayPtr documentIDs;
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
    if (ptr != NULL)
    {
        ptr->parent = NULL;
        GNETernaryTreeDestroy(ptr->lower);
        GNETernaryTreeDestroy(ptr->same);
        GNETernaryTreeDestroy(ptr->higher);
        GNEIntegerArrayDestroy(ptr->documentIDs);
        free(ptr);
    }
}


GNETernaryTreePtr GNETernaryTreeInsert(GNETernaryTreePtr ptr, const char *newCharacter, GNEInteger documentID)
{
    if (newCharacter == NULL) { return ptr; }

    if (ptr == NULL)
    {
        ptr = calloc(1, sizeof(GNETernaryTreeNode));
        if (ptr == NULL) { return ptr; }

        ptr->character = *newCharacter;
        ptr->parent = NULL;
        ptr->lower = NULL;
        ptr->same = NULL;
        ptr->higher = NULL;
        ptr->documentIDs = NULL;
    }
    else if (ptr->character == '\0') // Created by GNETernaryTreeCreate()
    {
        ptr->character = *newCharacter;
    }

    if (*newCharacter < ptr->character)
    {
        ptr->lower = GNETernaryTreeInsert(ptr->lower, newCharacter, documentID);
        ptr->lower->parent = ptr;
    }
    else if (*newCharacter == ptr->character)
    {
        if ('\0' == *newCharacter)
        {
            if (ptr->documentIDs == NULL)
            {
                ptr->documentIDs = GNEIntegerArrayCreate();
            }
            GNEIntegerArrayAddInteger(ptr->documentIDs, documentID);
        }
        else
        {
            ptr->same = GNETernaryTreeInsert(ptr->same, (newCharacter + 1), documentID);
            ptr->same->parent = ptr;
        }
    }
    else
    {
        ptr->higher = GNETernaryTreeInsert(ptr->higher, newCharacter, documentID);
        ptr->higher->parent = ptr;
    }

    return ptr;
}


GNEIntegerArrayPtr GNETernaryTreeSearch(GNETernaryTreePtr ptr, const char *target)
{
    GNETernaryTreePtr foundPtr = _GNETernaryTreeSearch(ptr, target);

    return (foundPtr != NULL) ? foundPtr->documentIDs : NULL;
}


GNEIntegerArrayPtr GNETernaryTreeSearchWithPrefix(GNETernaryTreePtr ptr, const char *prefix)
{
    GNETernaryTreePtr foundPtr = _GNETernaryTreeSearch(ptr, prefix);

    if (foundPtr == NULL) { return NULL; }

    GNEIntegerArrayPtr resultsPtr = GNEIntegerArrayCreate();

    if (resultsPtr == NULL) { return NULL; }

    if (_GNETernaryTreeSearchFromNode(foundPtr, resultsPtr) == FAILURE) { return NULL; }

    return (GNEIntegerArrayGetCount(resultsPtr) > 0) ? resultsPtr : NULL;
}


int GNETernaryTreeCopyContents(GNETernaryTreePtr ptr, char **outResults, size_t *outLength)
{
    if (ptr == NULL || outResults == NULL || outLength == NULL) { return FAILURE; }

    size_t length = 0;
    size_t resultsCapacity = 100;
    char *results = calloc(resultsCapacity, sizeof(char));
    if (results == NULL)
    {
        *outLength = 0;
        return FAILURE;
    }

    int ret = _GNETernaryTreeCopyContents(ptr, &results, &length, &resultsCapacity);
    if (ret == SUCCESS)
    {
        results[length] = '\0';
        length = length + 1;
        *outResults = results;
        *outLength = length;
    }
    else
    {
        free(results);
        *outLength = 0;
    }

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

    if (results) { free(results); results = NULL; }
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
GNETernaryTreePtr _GNETernaryTreeSearch(GNETernaryTreePtr ptr, const char *target)
{
    if (ptr == NULL) { return NULL; }

    const char targetCharacter = *target;

    if (targetCharacter != '\0' && targetCharacter < ptr->character)
    {
        return _GNETernaryTreeSearch(ptr->lower, target);
    }
    else if (targetCharacter != '\0' && targetCharacter > ptr->character)
    {
        return _GNETernaryTreeSearch(ptr->higher, target);
    }
    else
    {
        if (targetCharacter == '\0')
        {
            return ptr;
        }
        else
        {
            return _GNETernaryTreeSearch(ptr->same, ++target);
        }
    }
}


int _GNETernaryTreeSearchFromNode(GNETernaryTreePtr ptr, GNEIntegerArrayPtr results)
{
    if (ptr == NULL) { return SUCCESS; }

    if (_GNETernaryTreeSearchFromNode(ptr->lower, results) == FAILURE) { return FAILURE; }

    if (ptr->documentIDs != NULL)
    {
        if (GNEIntegerArrayAddIntegersFromArray(results, ptr->documentIDs) == FAILURE) { return FAILURE; }
    }

    if (_GNETernaryTreeSearchFromNode(ptr->same, results) == FAILURE) { return FAILURE; }

    return _GNETernaryTreeSearchFromNode(ptr->higher, results);
}


int _GNETernaryTreeCopyContents(GNETernaryTreePtr ptr,
                        char **outResults,
                        size_t *outLength,
                        size_t *outResultsCapacity)
{
    if (outResults == NULL || outLength == NULL || outResultsCapacity == NULL) { return FAILURE; }

    if (ptr == NULL) { return SUCCESS; }

    // We are at a leaf node. Print out the word by walking up the tree.
    if (ptr->lower == NULL && ptr->same == NULL && ptr->higher == NULL)
    {
        if (_GNETernaryTreeCopyWord(ptr, outResults, outLength, outResultsCapacity) == FAILURE) { return FAILURE; }

        return SUCCESS;
    }

    // First, go down the left branches of the tree.
    if (_GNETernaryTreeCopyContents(ptr->lower, outResults, outLength, outResultsCapacity) == FAILURE)
    {
        return FAILURE;
    }

    // We've found the end of a word. Append it to the results array.
    if (ptr->documentIDs != NULL)
    {
        if (_GNETernaryTreeCopyWord(ptr, outResults, outLength, outResultsCapacity) == FAILURE) { return FAILURE; }
    }

    // Proceed down the middle path to discover entries.
    if (_GNETernaryTreeCopyContents(ptr->same, outResults, outLength, outResultsCapacity) == FAILURE)
    {
        return FAILURE;
    }

    // Last, go down the right branches of the tree.
    return _GNETernaryTreeCopyContents(ptr->higher, outResults, outLength, outResultsCapacity);
}


int _GNETernaryTreeCopyWord(GNETernaryTreePtr ptr, char **outResults, size_t *outLength, size_t *outResultsCapacity)
{
    if (ptr == NULL) { return SUCCESS; }

    size_t wordLength = _GNETernaryTreeGetWordLength(ptr); // Does not include \0
    if (wordLength == 0) { return SUCCESS; }
    char *word = calloc((wordLength + 1), sizeof(char));

    size_t characterIndex = wordLength - 1;
    while (ptr != NULL)
    {
        if (_GNETernaryTreeIsLeaf(ptr) && ptr->character != '\0')
        {
            word[characterIndex] = ptr->character;
            characterIndex = characterIndex - 1;
        }
        else if (ptr->parent != NULL && ptr->parent->same == ptr)
        {
            word[characterIndex] = ptr->parent->character;
            characterIndex = characterIndex - 1;
        }
        ptr = ptr->parent;
    }

    // Separate words with new lines.
    word[wordLength] = '\n';
    wordLength = wordLength + 1;

    // If the results buffer isn't long enough to accomodate the word, increase its capacity.
    if ((*outResultsCapacity) < ((*outLength) + wordLength) &&
        _GNETernaryTreeIncreaseCharBuffer(outResults, outResultsCapacity, *outResultsCapacity) == FAILURE)
    {
        free(word);

        return FAILURE;
    }

    char *results = *outResults;
    size_t length = *outLength;
    for (size_t i = 0; i < wordLength; i++)
    {
        results[length + i] = word[i];
    }
    length += wordLength;
    *outResults = results;
    *outLength = length;
    free(word);

    return SUCCESS;
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
    if (ptr == NULL) { return 0; }

    size_t length = 0;

    while (ptr != NULL)
    {
        // If the node is a leaf node or is the same as the node's parent's 'same' pointer,
        // then the character is part of the word.
        if (_GNETernaryTreeIsLeaf(ptr) ||
            (ptr->parent != NULL && ptr->parent->same == ptr))
        {
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
