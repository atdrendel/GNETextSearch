//
//  GNETernaryTree.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "GNETernaryTree.h"


// ------------------------------------------------------------------------------------------


#define FAILURE 0
#define SUCCESS 1
#define FALSE 0
#define TRUE 1

GNETernaryTreePtr _GNETernaryTreeSearch(GNETernaryTreePtr ptr, const char *target);
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
        ptr = malloc(sizeof(GNETernaryTreeNode));
        if (ptr == NULL) { return ptr; }

        ptr->character = *newCharacter;
        ptr->parent = NULL;
        ptr->lower = NULL;
        ptr->same = NULL;
        ptr->higher = NULL;
        ptr->documentIDs = NULL;
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

    GNEIntegerArrayPtr resultsPtr = (foundPtr->documentIDs != NULL) ? foundPtr->documentIDs : GNEIntegerArrayCreate();

    return (resultsPtr != NULL && GNEIntegerArrayGetCount(resultsPtr) > 0) ? resultsPtr : NULL;
}


int GNETernaryTreeCopyContents(GNETernaryTreePtr ptr, char **outResults, size_t *outLength)
{
    if (ptr == NULL || outResults == NULL || outLength == NULL) { return FAILURE; }

    size_t length = 0;
    size_t bufferLength = 100;
    char *results = malloc(sizeof(char) * bufferLength);
    if (results == NULL)
    {
        *outLength = 0;
        return FAILURE;
    }

    int ret = _GNETernaryTreeCopyContents(ptr, &results, &length, &bufferLength);
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


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
GNETernaryTreePtr _GNETernaryTreeSearch(GNETernaryTreePtr ptr, const char *target)
{
    if (ptr == NULL) { return NULL; }

    if (*target < ptr->character)
    {
        return _GNETernaryTreeSearch(ptr->lower, target);
    }
    else if (*target > ptr->character)
    {
        return _GNETernaryTreeSearch(ptr->higher, target);
    }
    else
    {
        if ('\0' == *target)
        {
            return ptr;
        }
        else
        {
            return _GNETernaryTreeSearch(ptr->same, (target + 1));
        }
    }
}


int _GNETernaryTreeCopyContents(GNETernaryTreePtr ptr,
                        char **outResults,
                        size_t *outLength,
                        size_t *outBufferLength)
{
    if (outResults == NULL || outLength == NULL || outBufferLength == NULL) { return FAILURE; }

    if (ptr == NULL) { return SUCCESS; }

    // We are at a leaf node. Print out the word by walking up the tree.
    if (ptr->lower == NULL && ptr->same == NULL && ptr->higher == NULL)
    {
        if (_GNETernaryTreeCopyWord(ptr, outResults, outLength, outBufferLength) == FAILURE) { return FAILURE; }

        return SUCCESS;
    }

    // First, go down the left branches of the tree.
    if (_GNETernaryTreeCopyContents(ptr->lower, outResults, outLength, outBufferLength) == FAILURE)
    {
        return FAILURE;
    }

    // We've found the end of a word. Append it to the results array.
    if (ptr->documentIDs != NULL)
    {
        if (_GNETernaryTreeCopyWord(ptr, outResults, outLength, outBufferLength) == FAILURE) { return FAILURE; }
    }

    // Proceed down the middle path to discover entries.
    if (_GNETernaryTreeCopyContents(ptr->same, outResults, outLength, outBufferLength) == FAILURE)
    {
        return FAILURE;
    }

    // Last, go down the right branches of the tree.
    return _GNETernaryTreeCopyContents(ptr->higher, outResults, outLength, outBufferLength);
}


int _GNETernaryTreeCopyWord(GNETernaryTreePtr ptr, char **outResults, size_t *outLength, size_t *outBufferLength)
{
    if (ptr == NULL) { return SUCCESS; }

    size_t wordLength = _GNETernaryTreeGetWordLength(ptr); // Does not include \0
    if (wordLength == 0) { return SUCCESS; }
    char *word = malloc(sizeof(char) * (wordLength + 1));

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

    // If the results buffer isn't long enough to accomodate the word, increase its length.
    if ((*outBufferLength) < ((*outLength) + wordLength) &&
        _GNETernaryTreeIncreaseCharBuffer(outResults, outBufferLength, *outBufferLength) == FAILURE)
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
