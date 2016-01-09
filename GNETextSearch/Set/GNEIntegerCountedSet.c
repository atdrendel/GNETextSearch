//
//  GNEIntegerCountedSet.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/14/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include "GNEIntegerCountedSet.h"
#include "GNETextSearchPrivate.h"
#include <string.h>

// ------------------------------------------------------------------------------------------

#define LEFT_HEAVY 1
#define BALANCED 0
#define RIGHT_HEAVY -1

typedef struct _CountedSetNode * _CountedSetNodePtr;

typedef struct _CountedSetNode
{
    GNEInteger integer;
    size_t count;
    int balance;
    size_t left;
    size_t right;
} _CountedSetNode;


typedef struct GNEIntegerCountedSet
{
    _CountedSetNode *nodes;
    size_t count; // The number of nodes whose count > 0.
    size_t nodesCapacity;
    size_t insertIndex;
} GNEIntegerCountedSet;

// ------------------------------------------------------------------------------------------

_CountedSetNode * _GNEIntegerCountedSetCopyNodes(const GNEIntegerCountedSetPtr ptr);
int _GNEIntegerCountedSetCopyIntegers(const GNEIntegerCountedSetPtr ptr, GNEInteger *integers,
                                      const size_t integersCount);
int _CountedSetNodeCompare(const void *valuePtr1, const void *valuePtr2);
int _GNEIntegerCountedSetAddInteger(GNEIntegerCountedSetPtr ptr, GNEInteger newInteger, size_t countToAdd);
_CountedSetNodePtr _GNEIntegerCountedSetGetNodeForInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer);
size_t _GNEIntegerCountedSetGetIndexOfNodeForIntegerInsertion(GNEIntegerCountedSetPtr ptr, GNEInteger integer);
size_t _GNEIntegerCountedSetGetIndexOfNodeAndParentNodeForIntegerInsertion(GNEIntegerCountedSetPtr ptr,
                                                                           GNEInteger integer,
                                                                           size_t *outParentIndex);
int _GNEIntegerCountedSetBalanceNodeAtIndex(_CountedSetNode *nodes, size_t index);
void _GNEIntegerCountedSetRotateLeft(_CountedSetNode *nodes, size_t index);
void _GNEIntegerCountedSetRotateRight(_CountedSetNode *nodes, size_t index);
int _GNEIntegerCountedSetCreateNodeWithInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer,
                                               size_t count, size_t *outIndex);
int _GNEIntegerCountedSetIncreaseValuesBufferIfNeeded(GNEIntegerCountedSetPtr ptr);

// ------------------------------------------------------------------------------------------
#pragma mark - Counted Set
// ------------------------------------------------------------------------------------------
GNEIntegerCountedSetPtr GNEIntegerCountedSetCreate(void)
{
    GNEIntegerCountedSetPtr ptr = calloc(1, sizeof(GNEIntegerCountedSet));
    if (ptr == NULL) { return NULL; }

    size_t count = 5;
    size_t size = sizeof(_CountedSetNode);
    _CountedSetNode *nodes = calloc(count, size);
    if (nodes == NULL) { GNEIntegerCountedSetDestroy(ptr); return NULL; }

    ptr->nodes = nodes;
    ptr->count = 0;
    ptr->nodesCapacity = (count * size);
    ptr->insertIndex = 0;
    return ptr;
}


GNEIntegerCountedSetPtr GNEIntegerCountedSetCreateWithInteger(GNEInteger integer)
{
    GNEIntegerCountedSetPtr ptr = GNEIntegerCountedSetCreate();
    if (ptr == NULL) { return NULL; }
    if (GNEIntegerCountedSetAddInteger(ptr, integer) == failure) {
        GNEIntegerCountedSetDestroy(ptr);
        return NULL;
    }
    return ptr;
}


GNEIntegerCountedSetPtr GNEIntegerCountedSetCopy(GNEIntegerCountedSetPtr ptr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return NULL; }

    GNEIntegerCountedSetPtr copyPtr = calloc(1, sizeof(GNEIntegerCountedSet));
    if (copyPtr == NULL) { return NULL; }

    _CountedSetNode *nodes = malloc(ptr->nodesCapacity);
    if (nodes == NULL) { GNEIntegerCountedSetDestroy(copyPtr); return NULL; }

    memcpy(nodes, ptr->nodes, ptr->nodesCapacity);

    copyPtr->nodes = nodes;
    copyPtr->count = ptr->count;
    copyPtr->nodesCapacity = ptr->nodesCapacity;
    copyPtr->insertIndex = ptr->insertIndex;
    return copyPtr;
}


void GNEIntegerCountedSetDestroy(GNEIntegerCountedSetPtr ptr)
{
    if (ptr != NULL) {
        free(ptr->nodes);
        ptr->nodes = NULL;
        ptr->count = 0;
        ptr->nodesCapacity = 0;
        ptr->insertIndex = 0;
        free(ptr);
    }
}


size_t GNEIntegerCountedSetGetCount(GNEIntegerCountedSetPtr ptr)
{
    return (ptr == NULL) ? 0 : ptr->count;
}


bool GNEIntegerCountedSetContainsInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    _CountedSetNodePtr nodePtr = _GNEIntegerCountedSetGetNodeForInteger(ptr, integer);
    return (nodePtr == NULL || nodePtr->count == 0) ? false : true;
}


size_t GNEIntegerCountedSetGetCountForInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    if (ptr == NULL || ptr->nodes == NULL) { return 0; }
    _CountedSetNodePtr nodePtr = _GNEIntegerCountedSetGetNodeForInteger(ptr, integer);
    return (nodePtr == NULL) ? 0 : nodePtr->count;
}


result GNEIntegerCountedSetCopyIntegers(GNEIntegerCountedSetPtr ptr, GNEInteger **outIntegers, size_t *outCount)
{
    if (ptr == NULL || ptr->nodes == NULL || outIntegers == NULL || outCount == NULL) { return failure; }
    size_t integersCount = ptr->count;
    size_t size = sizeof(GNEInteger);
    GNEInteger *integers = calloc(integersCount, size);
    if (_GNEIntegerCountedSetCopyIntegers(ptr, integers, integersCount) == failure) {
        free(integers);
        *outCount = 0;
        return failure;
    }
    *outIntegers = integers;
    *outCount = integersCount;
    return success;
}


int GNEIntegerCountedSetAddInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    return _GNEIntegerCountedSetAddInteger(ptr, integer, 1);
}


int GNEIntegerCountedSetRemoveInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    if (ptr == NULL) { return failure; }
    _CountedSetNodePtr nodePtr = _GNEIntegerCountedSetGetNodeForInteger(ptr, integer);
    if (nodePtr == NULL || nodePtr->count == 0) { return success; }
    nodePtr->count = 0;
    ptr->count -= 1;
    return success;
}


int GNEIntegerCountedSetRemoveAllIntegers(GNEIntegerCountedSetPtr ptr)
{
    if (ptr == NULL) { return failure; }
    size_t count = ptr->insertIndex;
    for (size_t i = 0; i < count; i++) {
        ptr->nodes[i].count = 0;
    }
    ptr->count = 0;
    return success;
}


int GNEIntegerCountedSetUnionSet(GNEIntegerCountedSetPtr ptr, GNEIntegerCountedSetPtr otherPtr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    if (otherPtr == NULL || otherPtr->nodes == NULL) { return success; }

    size_t otherCount = otherPtr->count;
    _CountedSetNode *otherNodes = otherPtr->nodes;
    for (size_t i = 0; i < otherCount; i++) {
        _CountedSetNode otherValue = otherNodes[i];
        int result = _GNEIntegerCountedSetAddInteger(ptr, otherValue.integer, otherValue.count);
        if (result == failure) { return failure; }
    }
    return success;
}


int GNEIntegerCountedSetIntersectSet(GNEIntegerCountedSetPtr ptr, GNEIntegerCountedSetPtr otherPtr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    if (otherPtr == NULL || otherPtr->nodes == NULL) {
        return GNEIntegerCountedSetRemoveAllIntegers(ptr);
    }

    size_t actualCount = ptr->insertIndex;

    // Copy all of the counted set's values so that we can iterate over them
    // while modifying the set.
    _CountedSetNode *nodesCopy = _GNEIntegerCountedSetCopyNodes(ptr);
    if (nodesCopy == NULL) { return failure; }

    for (size_t i = 0; i < actualCount; i++) {
        _CountedSetNode node = nodesCopy[i];
        if (node.count == 0) { continue; }
        _CountedSetNodePtr nodePtr = _GNEIntegerCountedSetGetNodeForInteger(otherPtr, node.integer);
        if (nodePtr == NULL || nodePtr->count == 0) {
            int result = GNEIntegerCountedSetRemoveInteger(ptr, node.integer);
            if (result == failure) { free(nodesCopy); return failure; }
        } else {
            size_t count = GNEIntegerCountedSetGetCountForInteger(otherPtr, node.integer);
            int result = _GNEIntegerCountedSetAddInteger(ptr, node.integer, count);
            if (result == failure) { free(nodesCopy); return failure; }
        }
    }
    free(nodesCopy);
    return success;
}


int GNEIntegerCountedSetMinusSet(GNEIntegerCountedSetPtr ptr, GNEIntegerCountedSetPtr otherPtr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    if (otherPtr == NULL || otherPtr->nodes == NULL) { return success; }

    size_t otherUsedCount = otherPtr->insertIndex;
    _CountedSetNode *otherNodes = otherPtr->nodes;
    for (size_t i = 0; i < otherUsedCount; i++) {
        _CountedSetNode otherValue = otherNodes[i];
        _CountedSetNodePtr nodePtr = _GNEIntegerCountedSetGetNodeForInteger(ptr, otherValue.integer);
        if (nodePtr == NULL) { continue; }
        if (otherValue.count >= nodePtr->count) {
            int result = GNEIntegerCountedSetRemoveInteger(ptr, otherValue.integer);
            if (result == failure) { return failure; }
        } else {
            nodePtr->count -= otherValue.count;
        }
    }
    return success;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
_CountedSetNode * _GNEIntegerCountedSetCopyNodes(const GNEIntegerCountedSetPtr ptr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return NULL; }
    size_t actualCount = ptr->insertIndex;
    size_t size = sizeof(_CountedSetNode);
    _CountedSetNode *nodesCopy = calloc(actualCount, size);
    if (nodesCopy == NULL) { return failure; }
    memcpy(nodesCopy, ptr->nodes, actualCount * size);
    return nodesCopy;
}


int _GNEIntegerCountedSetCopyIntegers(const GNEIntegerCountedSetPtr ptr, GNEInteger *integers,
                                      const size_t integersCount)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    if (integers == NULL || integersCount == 0) { return failure; }

    size_t nodesCount = ptr->insertIndex;
    size_t size = sizeof(_CountedSetNode);
    if (integersCount > nodesCount) { return failure; }

    _CountedSetNode *nodesCopy = _GNEIntegerCountedSetCopyNodes(ptr);
    if (nodesCopy == NULL) { return failure; }

    qsort(nodesCopy, nodesCount, size, &_CountedSetNodeCompare);

    // The nodes are sorted in descending order. So, all of the nodes with zero counts
    // are at the end of the array. The integers count only includes nodes with
    // non-zero counts.
    for (size_t i = 0; i < integersCount; i++) {
        _CountedSetNode value = nodesCopy[i];
        integers[i] = value.integer;
    }
    free(nodesCopy);
    return success;
}


int _CountedSetNodeCompare(const void *valuePtr1, const void *valuePtr2)
{
    if (valuePtr1 == NULL || valuePtr2 == NULL) { return 0; }
    _CountedSetNode value1 = *(_CountedSetNode *)valuePtr1;
    _CountedSetNode value2 = *(_CountedSetNode *)valuePtr2;

    if (value1.count > value2.count) { return -1; }
    if (value1.count < value2.count) { return 1; }
    return 0;
}


int _GNEIntegerCountedSetAddInteger(GNEIntegerCountedSetPtr ptr, GNEInteger newInteger, size_t countToAdd)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    if (ptr->insertIndex == 0) {
        size_t index = SIZE_MAX;
        int result = _GNEIntegerCountedSetCreateNodeWithInteger(ptr, newInteger, countToAdd, &index);
        if (result == failure || index == SIZE_MAX) { return failure; }
        return success;
    }

    size_t parentIndex = SIZE_MAX;
    size_t insertIndex = _GNEIntegerCountedSetGetIndexOfNodeAndParentNodeForIntegerInsertion(ptr,
                                                                                             newInteger,
                                                                                             &parentIndex);
    if (insertIndex == SIZE_MAX) { return failure; }

    _CountedSetNode *nodePtr = &(ptr->nodes[insertIndex]);
    GNEInteger nodeInteger = nodePtr->integer;

    if (nodeInteger == newInteger) {
        size_t newCount = ((SIZE_MAX - nodePtr->count) >= countToAdd) ? (nodePtr->count + countToAdd) : SIZE_MAX;
        nodePtr->count = newCount;
        return success;
    }

    size_t index = SIZE_MAX;
    int result = _GNEIntegerCountedSetCreateNodeWithInteger(ptr, newInteger, countToAdd, &index);
    if (result == failure || index == SIZE_MAX) { return failure; }
    nodePtr = &(ptr->nodes[insertIndex]); // If ptr->nodes was realloced, we need to refresh the pointer.

    if (newInteger < nodeInteger) { nodePtr->left = index; }
    else { nodePtr->right = index; }

    _GNEIntegerCountedSetBalanceNodeAtIndex(ptr->nodes, parentIndex);

    return success;
}


/// Returns the exact node containing the specified integer or NULL if the integer isn't
/// present in the counted set.
_CountedSetNodePtr _GNEIntegerCountedSetGetNodeForInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    if (ptr == NULL || ptr->nodes == NULL || ptr->count == 0) { return NULL; }
    size_t index = _GNEIntegerCountedSetGetIndexOfNodeForIntegerInsertion(ptr, integer);
    if (index == SIZE_MAX) { return NULL; }
    _CountedSetNode *insertionNodePtr = &(ptr->nodes[index]);
    return (insertionNodePtr->integer == integer) ? insertionNodePtr : NULL;
}


/// Returns the node representing the specified integer or the parent node into which
/// a new node should be inserted. Return NULL on failure.
size_t _GNEIntegerCountedSetGetIndexOfNodeForIntegerInsertion(GNEIntegerCountedSetPtr ptr, GNEInteger integer)
{
    return _GNEIntegerCountedSetGetIndexOfNodeAndParentNodeForIntegerInsertion(ptr, integer, NULL);
}


size_t _GNEIntegerCountedSetGetIndexOfNodeAndParentNodeForIntegerInsertion(GNEIntegerCountedSetPtr ptr,
                                                                           GNEInteger integer,
                                                                           size_t *outParentIndex)
{
    if (ptr == NULL || ptr->nodes == NULL || ptr->insertIndex == 0) { return SIZE_MAX; }

    _CountedSetNode *nodes = ptr->nodes;
    size_t parentIndex = SIZE_MAX;
    size_t nextIndex = 0; // Start at root
    do {
        if (outParentIndex != NULL) { *outParentIndex = parentIndex; }
        parentIndex = nextIndex;
        if (integer < nodes[parentIndex].integer) { nextIndex = nodes[parentIndex].left; }
        else if (integer > nodes[parentIndex].integer) { nextIndex = nodes[parentIndex].right; }
        else { return parentIndex; }
    } while (nextIndex != SIZE_MAX);

    return parentIndex;
}


int _GNEIntegerCountedSetBalanceNodeAtIndex(_CountedSetNode *nodes, size_t index)
{
    if (nodes == NULL || index == SIZE_MAX) { return 0; }
    int leftHeight = _GNEIntegerCountedSetBalanceNodeAtIndex(nodes, nodes[index].left);
    int rightHeight = _GNEIntegerCountedSetBalanceNodeAtIndex(nodes, nodes[index].right);
    int height = leftHeight - rightHeight;
    if (abs(leftHeight - rightHeight) > 1) {
        if (height < 0) {
            _GNEIntegerCountedSetRotateRight(nodes, index);
        } else {
            _GNEIntegerCountedSetRotateLeft(nodes, index);
        }
        height = BALANCED;
    }
    nodes[index].balance = height;
    return abs(height) + 1;
}


void _GNEIntegerCountedSetRotateLeft(_CountedSetNode *nodes, size_t index)
{
    _CountedSetNode node = nodes[index];
    size_t childIndex = node.left;
    _CountedSetNode childNode = nodes[childIndex];
    size_t grandchildIndex = (childNode.balance > 0) ? childNode.left : childNode.right;
    _CountedSetNode grandchildNode = nodes[grandchildIndex];
    if (childNode.balance > 0) {
        //     8         7
        //   7    ==>  2   8
        // 2
        nodes[index] = childNode;
        nodes[index].left = grandchildIndex;
        nodes[index].right = childIndex;
        nodes[index].balance = BALANCED;

        nodes[childIndex] = node;
        nodes[childIndex].left = SIZE_MAX;
        nodes[childIndex].balance = BALANCED;
    } else {
        //   8         7
        // 2    ==>  2   8
        //   7
        nodes[index] = grandchildNode;
        nodes[index].left = childIndex;
        nodes[index].right = grandchildIndex;
        nodes[index].balance = BALANCED;

        nodes[grandchildIndex] = node;
        nodes[grandchildIndex].left = SIZE_MAX;
        nodes[grandchildIndex].balance = BALANCED;

        nodes[childIndex].right = SIZE_MAX;
        nodes[childIndex].balance = BALANCED;
    }
}


void _GNEIntegerCountedSetRotateRight(_CountedSetNode *nodes, size_t index)
{
    _CountedSetNode node = nodes[index];
    size_t childIndex = node.right;
    _CountedSetNode childNode = nodes[childIndex];
    size_t grandchildIndex = (childNode.balance > 0) ? childNode.left : childNode.right;
    _CountedSetNode grandchildNode = nodes[grandchildIndex];
    if (childNode.balance > 0) {
        // 2           7
        //   8  ==>  2   8
        // 7
        nodes[index] = grandchildNode;
        nodes[index].left = grandchildIndex;
        nodes[index].right = childIndex;
        nodes[index].balance = BALANCED;

        nodes[grandchildIndex] = node;
        nodes[grandchildIndex].left = SIZE_MAX;
        nodes[grandchildIndex].right = SIZE_MAX;
        nodes[grandchildIndex].balance = BALANCED;

        nodes[childIndex].left = SIZE_MAX;
        nodes[childIndex].balance = BALANCED;
    } else {
        // 2             7
        //   7    ==>  2   8
        //     8
        nodes[index] = childNode;
        nodes[index].left = childIndex;
        nodes[index].right = grandchildIndex;
        nodes[index].balance = BALANCED;

        nodes[childIndex] = node;
        nodes[childIndex].left = SIZE_MAX;
        nodes[childIndex].right = SIZE_MAX;
        nodes[childIndex].balance = BALANCED;
    }
}


/// Returns a pointer to a new counted set node and increments the GNEIntegerCountedSet's count.
int _GNEIntegerCountedSetCreateNodeWithInteger(GNEIntegerCountedSetPtr ptr, GNEInteger integer,
                                               size_t count, size_t *outIndex)
{
    if (outIndex == NULL) { return failure; }
    if (ptr == NULL || ptr->nodes == NULL) { *outIndex = SIZE_MAX; return failure; }
    if (ptr->insertIndex == SIZE_MAX - 1) { *outIndex = SIZE_MAX; return failure; }
    if (_GNEIntegerCountedSetIncreaseValuesBufferIfNeeded(ptr) == failure) {
        *outIndex = SIZE_MAX;
        return failure;
    }
    size_t index = ptr->insertIndex;
    ptr->insertIndex += 1;
    ptr->count += 1;
    ptr->nodes[index].integer = integer;
    ptr->nodes[index].count = count;
    ptr->nodes[index].balance = BALANCED;
    ptr->nodes[index].left = SIZE_MAX;
    ptr->nodes[index].right = SIZE_MAX;
    *outIndex = index;
    return success;
}


int _GNEIntegerCountedSetIncreaseValuesBufferIfNeeded(GNEIntegerCountedSetPtr ptr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    size_t usedCount = ptr->insertIndex;
    size_t capacity = ptr->nodesCapacity;
    size_t emptySpaces = (capacity / sizeof(_CountedSetNode)) - usedCount;
    if (emptySpaces <= 2) {
        size_t newCapacity = capacity * 2;
        _CountedSetNode *newNodes = realloc(ptr->nodes, newCapacity);
        if (newNodes == NULL) { return failure; }
        ptr->nodes = newNodes;
        ptr->nodesCapacity = newCapacity;
    }
    return success;
}
