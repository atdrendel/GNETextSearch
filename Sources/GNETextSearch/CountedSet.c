//
//  countedset.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/14/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include <GNETextSearch/CountedSet.h>
#include "GNETextSearchPrivate.h"
#include <limits.h>
#include <string.h>

// ------------------------------------------------------------------------------------------

typedef struct _tsearch_countedset_node
{
    GNEInteger integer;
    size_t count;
    int balance;
    size_t left;
    size_t right;
} _tsearch_countedset_node;


typedef struct tsearch_countedset
{
    _tsearch_countedset_node *nodes;
    size_t count; // The number of nodes whose count > 0.
    size_t nodesCapacity;
    size_t insertIndex;
} tsearch_countedset;

// ------------------------------------------------------------------------------------------

_tsearch_countedset_node * _tsearch_countedset_copy_nodes(const tsearch_countedset_ptr ptr);
result _tsearch_countedset_copy_ints(const tsearch_countedset_ptr ptr, GNEInteger *integers,
                                  const size_t integersCount);
int _tsearch_countedset_compare(const void *valuePtr1, const void *valuePtr2);
result _tsearch_countedset_add_int(const tsearch_countedset_ptr ptr,
                                   const GNEInteger newInteger, const size_t countToAdd);
_tsearch_countedset_node * _tsearch_countedset_get_node_for_int(const tsearch_countedset_ptr ptr,
                                                                const GNEInteger integer);
size_t _tsearch_countedset_get_node_idx_for_int_insert(const tsearch_countedset_ptr ptr, const GNEInteger integer);
size_t _tsearch_countedset_get_node_and_parent_idx_for_int_insert_with_path(const tsearch_countedset_ptr ptr,
                                                                            const GNEInteger integer,
                                                                            size_t *outParentIndex,
                                                                            size_t **path,
                                                                            size_t *pathCount,
                                                                            size_t *pathCapacity);
size_t _tsearch_countedset_get_node_and_parent_idx_for_int_insert(const tsearch_countedset_ptr ptr,
                                                                  const GNEInteger integer,
                                                                  size_t *outParentIndex);
int _tsearch_countedset_balance_node_at_idx(_tsearch_countedset_node *nodes, const size_t index);
static result _tsearch_countedset_rebalance_path(_tsearch_countedset_node *nodes,
                                                 const size_t *path,
                                                 const size_t pathCount);
static int _tsearch_countedset_node_height(_tsearch_countedset_node *nodes, const size_t index);
static void _tsearch_countedset_update_node_height(_tsearch_countedset_node *nodes, const size_t index);
static int _tsearch_countedset_node_balance_factor(_tsearch_countedset_node *nodes, const size_t index);
void _tsearch_countedset_rotate_left(_tsearch_countedset_node *nodes, const size_t index);
void _tsearch_countedset_rotate_right(_tsearch_countedset_node *nodes, const size_t index);
result _tsearch_countedset_node_init(const tsearch_countedset_ptr ptr, const GNEInteger integer,
                                     const size_t count, size_t *outIndex);
result _tsearch_countedset_increase_values_buf(const tsearch_countedset_ptr ptr);
static void _tsearch_countedset_swap_contents(tsearch_countedset_ptr a, tsearch_countedset_ptr b);
static result _tsearch_countedset_compact_if_needed(tsearch_countedset_ptr ptr);
static result _tsearch_countedset_index_stack_push(size_t **stack,
                                                   size_t *count,
                                                   size_t *capacity,
                                                   size_t index);

// ------------------------------------------------------------------------------------------
#pragma mark - Counted Set
// ------------------------------------------------------------------------------------------
tsearch_countedset_ptr tsearch_countedset_init(void)
{
    tsearch_countedset_ptr ptr = calloc(1, sizeof(tsearch_countedset));
    if (ptr == NULL) { return NULL; }

    size_t count = 5;
    size_t size = sizeof(_tsearch_countedset_node);
    _tsearch_countedset_node *nodes = calloc(count, size);
    if (nodes == NULL) { tsearch_countedset_free(ptr); return NULL; }

    ptr->nodes = nodes;
    ptr->count = 0;
    ptr->nodesCapacity = (count * size);
    ptr->insertIndex = 0;
    return ptr;
}


tsearch_countedset_ptr tsearch_countedset_copy(const tsearch_countedset_ptr ptr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return NULL; }

    tsearch_countedset_ptr copyPtr = calloc(1, sizeof(tsearch_countedset));
    if (copyPtr == NULL) { return NULL; }

    _tsearch_countedset_node *nodes = malloc(ptr->nodesCapacity);
    if (nodes == NULL) { tsearch_countedset_free(copyPtr); return NULL; }

    memcpy(nodes, ptr->nodes, ptr->nodesCapacity);

    copyPtr->nodes = nodes;
    copyPtr->count = ptr->count;
    copyPtr->nodesCapacity = ptr->nodesCapacity;
    copyPtr->insertIndex = ptr->insertIndex;
    return copyPtr;
}


void tsearch_countedset_free(const tsearch_countedset_ptr ptr)
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


size_t tsearch_countedset_get_count(const tsearch_countedset_ptr ptr)
{
    return (ptr == NULL) ? 0 : ptr->count;
}


bool tsearch_countedset_contains_int(const tsearch_countedset_ptr ptr, const GNEInteger integer)
{
    _tsearch_countedset_node *nodePtr = _tsearch_countedset_get_node_for_int(ptr, integer);
    return (nodePtr == NULL || nodePtr->count == 0) ? false : true;
}


size_t tsearch_countedset_get_count_for_int(const tsearch_countedset_ptr ptr, const GNEInteger integer)
{
    if (ptr == NULL || ptr->nodes == NULL) { return 0; }
    _tsearch_countedset_node *nodePtr = _tsearch_countedset_get_node_for_int(ptr, integer);
    return (nodePtr == NULL) ? 0 : nodePtr->count;
}


result tsearch_countedset_copy_ints(const tsearch_countedset_ptr ptr, GNEInteger **outIntegers, size_t *outCount)
{
    if (outIntegers == NULL || outCount == NULL) { return failure; }
    *outIntegers = NULL;
    *outCount = 0;

    if (ptr == NULL || ptr->nodes == NULL) { return failure; }

    size_t integersCount = ptr->count;
    if (integersCount == 0) { return success; }

    size_t size = sizeof(GNEInteger);
    size_t byteLength = 0;
    if (_tsearch_size_mul_overflows(integersCount, size, &byteLength)) {
        return failure;
    }

    GNEInteger *integers = malloc(byteLength);
    if (integers == NULL) { return failure; }

    if (_tsearch_countedset_copy_ints(ptr, integers, integersCount) == failure) {
        free(integers);
        return failure;
    }

    *outIntegers = integers;
    *outCount = integersCount;
    return success;
}


result tsearch_countedset_add_int(const tsearch_countedset_ptr ptr, const GNEInteger integer)
{
    return _tsearch_countedset_add_int(ptr, integer, 1);
}


result tsearch_countedset_remove_int(const tsearch_countedset_ptr ptr, const GNEInteger integer)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    _tsearch_countedset_node *nodePtr = _tsearch_countedset_get_node_for_int(ptr, integer);
    if (nodePtr == NULL || nodePtr->count == 0) { return success; }
    nodePtr->count = 0;
    ptr->count -= 1;
    (void)_tsearch_countedset_compact_if_needed(ptr);
    return success;
}


result tsearch_countedset_remove_all_ints(const tsearch_countedset_ptr ptr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    size_t count = ptr->insertIndex;
    for (size_t i = 0; i < count; i++) {
        ptr->nodes[i].count = 0;
    }
    ptr->count = 0;
    (void)_tsearch_countedset_compact_if_needed(ptr);
    return success;
}


result tsearch_countedset_union(const tsearch_countedset_ptr ptr, const tsearch_countedset_ptr otherPtr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    if (otherPtr == NULL || otherPtr->nodes == NULL) { return success; }

    size_t otherCount = otherPtr->insertIndex;
    _tsearch_countedset_node *otherNodes = otherPtr->nodes;
    for (size_t i = 0; i < otherCount; i++) {
        if (otherNodes[i].count == 0) { continue; }
        _tsearch_countedset_node otherValue = otherNodes[i];
        int result = _tsearch_countedset_add_int(ptr, otherValue.integer, otherValue.count);
        if (result == failure) { return failure; }
    }

    return success;
}


result tsearch_countedset_intersect(const tsearch_countedset_ptr ptr, const tsearch_countedset_ptr otherPtr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }

    if (otherPtr == NULL || otherPtr->nodes == NULL || otherPtr->count == 0) {
        return tsearch_countedset_remove_all_ints(ptr);
    }

    size_t actualCount = ptr->insertIndex;
    if (actualCount == 0) { return success; }

    // Copy all of the counted set's values so that we can iterate over them
    // while modifying the set.
    _tsearch_countedset_node *nodesCopy = _tsearch_countedset_copy_nodes(ptr);
    if (nodesCopy == NULL) { return failure; }

    for (size_t i = 0; i < actualCount; i++) {
        _tsearch_countedset_node node = nodesCopy[i];
        if (node.count == 0) { continue; }
        _tsearch_countedset_node *nodePtr = _tsearch_countedset_get_node_for_int(otherPtr, node.integer);
        if (nodePtr == NULL || nodePtr->count == 0) {
            int result = tsearch_countedset_remove_int(ptr, node.integer);
            if (result == failure) {
                free(nodesCopy);
                return failure;
            }
        } else {
            size_t count = tsearch_countedset_get_count_for_int(otherPtr, node.integer);
            int result = _tsearch_countedset_add_int(ptr, node.integer, count);
            if (result == failure) {
                free(nodesCopy);
                return failure;
            }
        }
    }

    free(nodesCopy);
    return _tsearch_countedset_compact_if_needed(ptr);
}


result tsearch_countedset_minus(const tsearch_countedset_ptr ptr, const tsearch_countedset_ptr otherPtr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    if (otherPtr == NULL || otherPtr->nodes == NULL) { return success; }

    size_t otherUsedCount = otherPtr->insertIndex;
    _tsearch_countedset_node *otherNodes = otherPtr->nodes;
    for (size_t i = 0; i < otherUsedCount; i++) {
        _tsearch_countedset_node otherValue = otherNodes[i];
        if (otherValue.count == 0) { continue; }

        _tsearch_countedset_node *nodePtr = _tsearch_countedset_get_node_for_int(ptr, otherValue.integer);
        if (nodePtr == NULL || nodePtr->count == 0) { continue; }

        if (otherValue.count >= nodePtr->count) {
            int result = tsearch_countedset_remove_int(ptr, otherValue.integer);
            if (result == failure) { return failure; }
        } else {
            nodePtr->count -= otherValue.count;
        }
    }

    return _tsearch_countedset_compact_if_needed(ptr);
}


result _tsearch_countedset_copy_items(const tsearch_countedset_ptr ptr,
                                      _tsearch_countedset_item **outItems,
                                      size_t *outCount)
{
    if (outItems == NULL || outCount == NULL) { return failure; }
    *outItems = NULL;
    *outCount = 0;

    if (ptr == NULL || ptr->nodes == NULL || ptr->count == 0) { return success; }

    size_t byteLength = 0;
    if (_tsearch_size_mul_overflows(ptr->count, sizeof(_tsearch_countedset_item), &byteLength)) {
        return failure;
    }

    _tsearch_countedset_item *items = malloc(byteLength);
    if (items == NULL) { return failure; }

    size_t itemIndex = 0;
    for (size_t i = 0; i < ptr->insertIndex; i++) {
        _tsearch_countedset_node node = ptr->nodes[i];
        if (node.count == 0) { continue; }
        if (itemIndex >= ptr->count) {
            free(items);
            return failure;
        }

        items[itemIndex].integer = node.integer;
        items[itemIndex].count = node.count;
        itemIndex += 1;
    }

    if (itemIndex != ptr->count) {
        free(items);
        return failure;
    }

    *outItems = items;
    *outCount = itemIndex;
    return success;
}


result _tsearch_countedset_add_int_count(const tsearch_countedset_ptr ptr,
                                         const GNEInteger integer,
                                         const size_t count)
{
    return _tsearch_countedset_add_int(ptr, integer, count);
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
_tsearch_countedset_node * _tsearch_countedset_copy_nodes(const tsearch_countedset_ptr ptr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return NULL; }
    size_t actualCount = ptr->insertIndex;
    if (actualCount == 0) { return NULL; }

    size_t size = sizeof(_tsearch_countedset_node);
    size_t byteLength = 0;
    if (_tsearch_size_mul_overflows(actualCount, size, &byteLength)) {
        return NULL;
    }

    _tsearch_countedset_node *nodesCopy = malloc(byteLength);
    if (nodesCopy == NULL) { return NULL; }

    memcpy(nodesCopy, ptr->nodes, byteLength);
    return nodesCopy;
}


result _tsearch_countedset_copy_ints(const tsearch_countedset_ptr ptr, GNEInteger *integers,
                                     const size_t integersCount)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    if (integers == NULL || integersCount == 0) { return failure; }

    size_t nodesCount = ptr->insertIndex;
    size_t size = sizeof(_tsearch_countedset_node);
    if (integersCount > nodesCount) { return failure; }

    _tsearch_countedset_node *nodesCopy = _tsearch_countedset_copy_nodes(ptr);
    if (nodesCopy == NULL) { return failure; }

    qsort(nodesCopy, nodesCount, size, &_tsearch_countedset_compare);

    // The nodes are sorted in descending order. So, all of the nodes with zero counts
    // are at the end of the array. The integers count only includes nodes with
    // non-zero counts.
    for (size_t i = 0; i < integersCount; i++) {
        _tsearch_countedset_node value = nodesCopy[i];
        integers[i] = value.integer;
    }
    free(nodesCopy);
    return success;
}


int _tsearch_countedset_compare(const void *valuePtr1, const void *valuePtr2)
{
    if (valuePtr1 == NULL || valuePtr2 == NULL) { return 0; }
    _tsearch_countedset_node value1 = *(_tsearch_countedset_node *)valuePtr1;
    _tsearch_countedset_node value2 = *(_tsearch_countedset_node *)valuePtr2;

    if (value1.count > value2.count) { return -1; }
    if (value1.count < value2.count) { return 1; }
    return 0;
}


result _tsearch_countedset_add_int(const tsearch_countedset_ptr ptr,
                                   const GNEInteger newInteger,
                                   const size_t countToAdd)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    if (countToAdd == 0) { return success; }

    if (ptr->insertIndex == 0) {
        size_t index = SIZE_MAX;
        int result = _tsearch_countedset_node_init(ptr, newInteger, countToAdd, &index);
        if (result == failure || index == SIZE_MAX) { return failure; }
        return success;
    }

    size_t *path = NULL;
    size_t pathCount = 0;
    size_t pathCapacity = 0;
    size_t insertIndex = _tsearch_countedset_get_node_and_parent_idx_for_int_insert_with_path(ptr,
                                                                                              newInteger,
                                                                                              NULL,
                                                                                              &path,
                                                                                              &pathCount,
                                                                                              &pathCapacity);
    if (insertIndex == SIZE_MAX) {
        free(path);
        return failure;
    }

    _tsearch_countedset_node *nodePtr = &(ptr->nodes[insertIndex]);
    GNEInteger nodeInteger = nodePtr->integer;

    if (nodeInteger == newInteger) {
        size_t newCount = 0;
        if (_tsearch_size_add_overflows(nodePtr->count, countToAdd, &newCount)) {
            free(path);
            return failure;
        }

        if (nodePtr->count == 0 && newCount > 0) {
            size_t activeCount = 0;
            if (_tsearch_size_add_overflows(ptr->count, 1, &activeCount)) {
                free(path);
                return failure;
            }
            ptr->count = activeCount;
        }

        nodePtr->count = newCount;
        free(path);
        return success;
    }

    size_t index = SIZE_MAX;
    int result = _tsearch_countedset_node_init(ptr, newInteger, countToAdd, &index);
    if (result == failure || index == SIZE_MAX) {
        free(path);
        return failure;
    }
    nodePtr = &(ptr->nodes[insertIndex]); // If ptr->nodes was realloced, we need to refresh the pointer.

    if (newInteger < nodeInteger) { nodePtr->left = index; }
    else { nodePtr->right = index; }

    if (_tsearch_countedset_rebalance_path(ptr->nodes, path, pathCount) == failure) {
        free(path);
        return failure;
    }

    free(path);

    return success;
}


/// Returns the exact node containing the specified integer or NULL if the integer isn't
/// present in the counted set.
_tsearch_countedset_node * _tsearch_countedset_get_node_for_int(const tsearch_countedset_ptr ptr,
                                                                const GNEInteger integer)
{
    if (ptr == NULL || ptr->nodes == NULL || ptr->count == 0) { return NULL; }
    size_t index = _tsearch_countedset_get_node_idx_for_int_insert(ptr, integer);
    if (index == SIZE_MAX) { return NULL; }
    _tsearch_countedset_node *insertionNodePtr = &(ptr->nodes[index]);
    return (insertionNodePtr->integer == integer) ? insertionNodePtr : NULL;
}


/// Returns the index for the node representing the specified integer or the parent node into which
/// a new node should be inserted. Returns SIZE_MAX on failure.
size_t _tsearch_countedset_get_node_idx_for_int_insert(const tsearch_countedset_ptr ptr, const GNEInteger integer)
{
    return _tsearch_countedset_get_node_and_parent_idx_for_int_insert(ptr, integer, NULL);
}


size_t _tsearch_countedset_get_node_and_parent_idx_for_int_insert(const tsearch_countedset_ptr ptr,
                                                                  const GNEInteger integer,
                                                                  size_t *outParentIndex)
{
    return _tsearch_countedset_get_node_and_parent_idx_for_int_insert_with_path(ptr,
                                                                                integer,
                                                                                outParentIndex,
                                                                                NULL,
                                                                                NULL,
                                                                                NULL);
}


size_t _tsearch_countedset_get_node_and_parent_idx_for_int_insert_with_path(const tsearch_countedset_ptr ptr,
                                                                            const GNEInteger integer,
                                                                            size_t *outParentIndex,
                                                                            size_t **path,
                                                                            size_t *pathCount,
                                                                            size_t *pathCapacity)
{
    if (ptr == NULL || ptr->nodes == NULL || ptr->insertIndex == 0) { return SIZE_MAX; }

    _tsearch_countedset_node *nodes = ptr->nodes;
    size_t parentIndex = SIZE_MAX;
    size_t nextIndex = 0; // Start at root
    do {
        if (outParentIndex != NULL) { *outParentIndex = parentIndex; }
        parentIndex = nextIndex;
        if (path != NULL &&
            pathCount != NULL &&
            pathCapacity != NULL &&
            _tsearch_countedset_index_stack_push(path, pathCount, pathCapacity, parentIndex) == failure) {
            return SIZE_MAX;
        }

        if (integer < nodes[parentIndex].integer) { nextIndex = nodes[parentIndex].left; }
        else if (integer > nodes[parentIndex].integer) { nextIndex = nodes[parentIndex].right; }
        else { return parentIndex; }
    } while (nextIndex != SIZE_MAX);

    return parentIndex;
}


int _tsearch_countedset_balance_node_at_idx(_tsearch_countedset_node *nodes, const size_t index)
{
    if (nodes == NULL || index == SIZE_MAX) { return 0; }
    _tsearch_countedset_update_node_height(nodes, index);
    return _tsearch_countedset_node_height(nodes, index);
}


static result _tsearch_countedset_rebalance_path(_tsearch_countedset_node *nodes,
                                                 const size_t *path,
                                                 const size_t pathCount)
{
    if (nodes == NULL || path == NULL) { return failure; }

    for (size_t i = pathCount; i > 0; i--) {
        size_t index = path[i - 1];
        if (index == SIZE_MAX) { return failure; }

        _tsearch_countedset_update_node_height(nodes, index);
        int balance = _tsearch_countedset_node_balance_factor(nodes, index);

        if (balance > 1) {
            size_t leftIndex = nodes[index].left;
            if (leftIndex == SIZE_MAX) { return failure; }
            if (_tsearch_countedset_node_balance_factor(nodes, leftIndex) < 0) {
                _tsearch_countedset_rotate_right(nodes, leftIndex);
            }
            _tsearch_countedset_rotate_left(nodes, index);
        } else if (balance < -1) {
            size_t rightIndex = nodes[index].right;
            if (rightIndex == SIZE_MAX) { return failure; }
            if (_tsearch_countedset_node_balance_factor(nodes, rightIndex) > 0) {
                _tsearch_countedset_rotate_left(nodes, rightIndex);
            }
            _tsearch_countedset_rotate_right(nodes, index);
        }
    }

    return success;
}


static int _tsearch_countedset_node_height(_tsearch_countedset_node *nodes, const size_t index)
{
    if (nodes == NULL || index == SIZE_MAX) { return 0; }
    return nodes[index].balance;
}


static void _tsearch_countedset_update_node_height(_tsearch_countedset_node *nodes, const size_t index)
{
    if (nodes == NULL || index == SIZE_MAX) { return; }

    int leftHeight = _tsearch_countedset_node_height(nodes, nodes[index].left);
    int rightHeight = _tsearch_countedset_node_height(nodes, nodes[index].right);
    int maxHeight = (leftHeight > rightHeight) ? leftHeight : rightHeight;
    nodes[index].balance = (maxHeight == INT_MAX) ? INT_MAX : maxHeight + 1;
}


static int _tsearch_countedset_node_balance_factor(_tsearch_countedset_node *nodes, const size_t index)
{
    if (nodes == NULL || index == SIZE_MAX) { return 0; }

    int leftHeight = _tsearch_countedset_node_height(nodes, nodes[index].left);
    int rightHeight = _tsearch_countedset_node_height(nodes, nodes[index].right);
    return leftHeight - rightHeight;
}


void _tsearch_countedset_rotate_left(_tsearch_countedset_node *nodes, const size_t index)
{
    if (nodes == NULL || index == SIZE_MAX) { return; }

    _tsearch_countedset_node node = nodes[index];
    size_t childIndex = node.left;
    if (childIndex == SIZE_MAX) { return; }

    _tsearch_countedset_node childNode = nodes[childIndex];
    size_t grandchildIndex = childNode.right;

    nodes[index] = childNode;
    nodes[index].right = childIndex;

    nodes[childIndex] = node;
    nodes[childIndex].left = grandchildIndex;

    _tsearch_countedset_update_node_height(nodes, childIndex);
    _tsearch_countedset_update_node_height(nodes, index);
}


void _tsearch_countedset_rotate_right(_tsearch_countedset_node *nodes, const size_t index)
{
    if (nodes == NULL || index == SIZE_MAX) { return; }

    _tsearch_countedset_node node = nodes[index];
    size_t childIndex = node.right;
    if (childIndex == SIZE_MAX) { return; }

    _tsearch_countedset_node childNode = nodes[childIndex];
    size_t grandchildIndex = childNode.left;

    nodes[index] = childNode;
    nodes[index].left = childIndex;

    nodes[childIndex] = node;
    nodes[childIndex].right = grandchildIndex;

    _tsearch_countedset_update_node_height(nodes, childIndex);
    _tsearch_countedset_update_node_height(nodes, index);
}


/// Returns a pointer to a new counted set node and increments the GNEIntegerCountedSet's count.
result _tsearch_countedset_node_init(const tsearch_countedset_ptr ptr, const GNEInteger integer,
                                     const size_t count, size_t *outIndex)
{
    if (outIndex == NULL) { return failure; }
    if (ptr == NULL || ptr->nodes == NULL) { *outIndex = SIZE_MAX; return failure; }
    if (count == 0) { *outIndex = SIZE_MAX; return success; }

    if (_tsearch_countedset_increase_values_buf(ptr) == failure) {
        *outIndex = SIZE_MAX;
        return failure;
    }

    size_t index = ptr->insertIndex;
    size_t nextInsertIndex = 0;
    size_t activeCount = 0;
    if (_tsearch_size_add_overflows(ptr->insertIndex, 1, &nextInsertIndex) ||
        _tsearch_size_add_overflows(ptr->count, 1, &activeCount)) {
        *outIndex = SIZE_MAX;
        return failure;
    }

    ptr->insertIndex = nextInsertIndex;
    ptr->count = activeCount;
    ptr->nodes[index].integer = integer;
    ptr->nodes[index].count = count;
    ptr->nodes[index].balance = 1;
    ptr->nodes[index].left = SIZE_MAX;
    ptr->nodes[index].right = SIZE_MAX;
    *outIndex = index;
    return success;
}


result _tsearch_countedset_increase_values_buf(const tsearch_countedset_ptr ptr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }

    size_t nodeCountCapacity = ptr->nodesCapacity / sizeof(_tsearch_countedset_node);
    if (ptr->insertIndex > nodeCountCapacity) { return failure; }

    size_t emptySpaces = nodeCountCapacity - ptr->insertIndex;
    if (emptySpaces > 2) { return success; }

    size_t newCapacity = 0;
    if (_tsearch_size_mul_overflows(ptr->nodesCapacity, 2, &newCapacity)) {
        return failure;
    }

    _tsearch_countedset_node *newNodes = realloc(ptr->nodes, newCapacity);
    if (newNodes == NULL) { return failure; }

    ptr->nodes = newNodes;
    ptr->nodesCapacity = newCapacity;
    return success;
}


static void _tsearch_countedset_swap_contents(tsearch_countedset_ptr a, tsearch_countedset_ptr b)
{
    if (a == NULL || b == NULL) { return; }

    tsearch_countedset tmp = *a;
    *a = *b;
    *b = tmp;
}


static result _tsearch_countedset_compact_if_needed(tsearch_countedset_ptr ptr)
{
    if (ptr == NULL || ptr->nodes == NULL) { return failure; }
    if (ptr->insertIndex < 64) { return success; }

    size_t tombstones = ptr->insertIndex - ptr->count;
    if (tombstones < (ptr->insertIndex / 2)) { return success; }

    tsearch_countedset_ptr rebuilt = tsearch_countedset_init();
    if (rebuilt == NULL) { return failure; }

    for (size_t i = 0; i < ptr->insertIndex; i++) {
        _tsearch_countedset_node node = ptr->nodes[i];
        if (node.count == 0) { continue; }
        if (_tsearch_countedset_add_int(rebuilt, node.integer, node.count) == failure) {
            tsearch_countedset_free(rebuilt);
            return failure;
        }
    }

    _tsearch_countedset_swap_contents(ptr, rebuilt);
    tsearch_countedset_free(rebuilt);
    return success;
}


static result _tsearch_countedset_index_stack_push(size_t **stack,
                                                   size_t *count,
                                                   size_t *capacity,
                                                   size_t index)
{
    if (stack == NULL || count == NULL || capacity == NULL) { return failure; }

    if (*count >= *capacity) {
        size_t newCapacity = 0;
        size_t byteLength = 0;

        if (*capacity == 0) {
            newCapacity = 64;
            if (_tsearch_size_mul_overflows(newCapacity, sizeof(size_t), &byteLength)) {
                return failure;
            }
        } else {
            newCapacity = *capacity;
            if (_tsearch_next_buf_len(&newCapacity, sizeof(size_t), &byteLength) == failure) {
                return failure;
            }
        }

        size_t *newStack = realloc(*stack, byteLength);
        if (newStack == NULL) { return failure; }

        *stack = newStack;
        *capacity = newCapacity;
    }

    (*stack)[*count] = index;
    *count += 1;
    return success;
}
