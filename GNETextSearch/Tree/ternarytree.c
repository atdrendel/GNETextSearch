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

typedef int callback_signal;
#define callback_continue 0
#define callback_stop 1
typedef callback_signal(*reverse_search_func)(const char character, const size_t index, const void *context);

typedef struct _tsearch_string_search
{
    const char *string;
    const size_t length;
    size_t currentIndex;
    bool didMatch;
} _tsearch_string_search;

typedef struct _tsearch_partial_search_item
{
    tsearch_ternarytree_ptr node;
    size_t currentIndex;
} _tsearch_partial_search_item;

// ------------------------------------------------------------------------------------------

static bool _tsearch_cstring_is_nonempty(const char *string);
tsearch_ternarytree_ptr _tsearch_ternarytree_search(tsearch_ternarytree_ptr ptr, const char *target);
result _tsearch_ternarytree_copy_words_from_node(const tsearch_ternarytree_ptr ptr, tsearch_countedset_ptr results);
static result _tsearch_build_prefix_table(const char *target, const size_t length, size_t **outTable);
static size_t _tsearch_kmp_next_index(const char *target,
                                      const size_t *prefixTable,
                                      size_t currentIndex,
                                      const char character);
result _tsearch_ternarytree_find_partial_match(const tsearch_ternarytree_ptr ptr,
                                               const char *target,
                                               const size_t length,
                                               const size_t *prefixTable,
                                               size_t currentIndex,
                                               tsearch_countedset_ptr results);
result _tsearch_ternarytree_find_suffix(const tsearch_ternarytree_ptr ptr, const char *suffix,
                                        const size_t length, tsearch_countedset_ptr results);
result _tsearch_ternarytree_reverse_search_from_node(tsearch_ternarytree_ptr ptr, reverse_search_func callback,
                                                     void *context);
result _tsearch_ternarytree_copy_contents(tsearch_ternarytree_ptr ptr, tsearch_stringbuf_ptr contentsPtr);
result _tsearch_ternarytree_copy_word(const tsearch_ternarytree_ptr ptr, const tsearch_stringbuf_ptr contentsPtr);
callback_signal _tsearch_ternarytree_suffix_search_callback(const char character,
                                                            const size_t index, const void *context);
callback_signal _tsearch_ternarytree_copy_word_callback(const char character,
                                                        const size_t index, const void *context);
result _tsearch_ternarytree_is_leaf(const tsearch_ternarytree_ptr ptr);
size_t _tsearch_ternarytree_get_word_len(const tsearch_ternarytree_ptr ptr);
bool _tsearch_ternarytree_has_valid_document_ids(const tsearch_ternarytree_ptr ptr);
static result _tsearch_partial_search_stack_push(_tsearch_partial_search_item **stack,
                                                 size_t *count,
                                                 size_t *capacity,
                                                 _tsearch_partial_search_item item);

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


void tsearch_ternarytree_free(const tsearch_ternarytree_ptr ptr)
{
    if (ptr == NULL) { return; }

    tsearch_ternarytree_ptr stopParent = ptr->parent;
    tsearch_ternarytree_ptr previous = stopParent;
    tsearch_ternarytree_ptr current = ptr;

    while (current != stopParent) {
        tsearch_ternarytree_ptr next = NULL;
        bool shouldFree = false;

        if (previous == current->parent) {
            if (current->lower != NULL) { next = current->lower; }
            else if (current->same != NULL) { next = current->same; }
            else if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; shouldFree = true; }
        } else if (previous == current->lower) {
            if (current->same != NULL) { next = current->same; }
            else if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; shouldFree = true; }
        } else if (previous == current->same) {
            if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; shouldFree = true; }
        } else {
            next = current->parent;
            shouldFree = true;
        }

        previous = current;
        if (shouldFree == true) {
            tsearch_countedset_free(current->documentIDs);
            current->documentIDs = NULL;
            free(current);
        }
        current = next;
    }
}


tsearch_ternarytree_ptr tsearch_ternarytree_insert(tsearch_ternarytree_ptr ptr,
                                                   const char *newCharacter,
                                                   const GNEInteger documentID)
{
    if (!_tsearch_cstring_is_nonempty(newCharacter)) { return ptr; }

    if (ptr == NULL) {
        ptr = tsearch_ternarytree_init();
        if (ptr == NULL) { return ptr; }
    }

    tsearch_ternarytree_ptr root = ptr;
    tsearch_ternarytree_ptr node = ptr;
    const char *cursor = newCharacter;

    while (true) {
        if (node->character == '\0') { node->character = *cursor; }

        if (*cursor < node->character) {
            if (node->lower == NULL) {
                node->lower = tsearch_ternarytree_init();
                if (node->lower == NULL) { return root; }
                node->lower->parent = node;
            }
            node = node->lower;
            continue;
        }

        if (*cursor > node->character) {
            if (node->higher == NULL) {
                node->higher = tsearch_ternarytree_init();
                if (node->higher == NULL) { return root; }
                node->higher->parent = node;
            }
            node = node->higher;
            continue;
        }

        if (cursor[1] == '\0') {
            if (node->documentIDs == NULL) {
                node->documentIDs = tsearch_countedset_init();
                if (node->documentIDs == NULL) { return root; }
            }

            (void)tsearch_countedset_add_int(node->documentIDs, documentID);
            return root;
        }

        cursor += 1;
        if (node->same == NULL) {
            node->same = tsearch_ternarytree_init();
            if (node->same == NULL) { return root; }
            node->same->parent = node;
        }
        node = node->same;
    }
}


result tsearch_ternarytree_remove(const tsearch_ternarytree_ptr ptr, const GNEInteger documentID)
{
    if (ptr == NULL) { return success; }

    tsearch_ternarytree_ptr stopParent = ptr->parent;
    tsearch_ternarytree_ptr previous = stopParent;
    tsearch_ternarytree_ptr current = ptr;

    while (current != stopParent) {
        tsearch_ternarytree_ptr next = NULL;

        if (previous == current->parent) {
            if (_tsearch_ternarytree_has_valid_document_ids(current) == true &&
                tsearch_countedset_remove_int(current->documentIDs, documentID) == failure) {
                return failure;
            }

            if (current->lower != NULL) { next = current->lower; }
            else if (current->same != NULL) { next = current->same; }
            else if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; }
        } else if (previous == current->lower) {
            if (current->same != NULL) { next = current->same; }
            else if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; }
        } else if (previous == current->same) {
            if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; }
        } else {
            next = current->parent;
        }

        previous = current;
        current = next;
    }

    return success;
}


tsearch_countedset_ptr tsearch_ternarytree_copy_search_results(const tsearch_ternarytree_ptr ptr, const char *target)
{
    if (ptr == NULL || !_tsearch_cstring_is_nonempty(target)) { return NULL; }

    tsearch_ternarytree_ptr foundPtr = _tsearch_ternarytree_search(ptr, target);
    bool hasResults = _tsearch_ternarytree_has_valid_document_ids(foundPtr);
    return (hasResults == true) ? tsearch_countedset_copy(foundPtr->documentIDs) : NULL;
}


tsearch_countedset_ptr tsearch_ternarytree_copy_prefix_search_results(const tsearch_ternarytree_ptr ptr, const char *prefix)
{
    if (ptr == NULL || !_tsearch_cstring_is_nonempty(prefix)) { return NULL; }

    tsearch_ternarytree_ptr foundPtr = _tsearch_ternarytree_search(ptr, prefix);
    if (foundPtr == NULL) { return NULL; }

    tsearch_countedset_ptr resultsPtr = tsearch_countedset_init();
    if (resultsPtr == NULL) { return NULL; }

    if (_tsearch_ternarytree_has_valid_document_ids(foundPtr) == true) {
        if (tsearch_countedset_union(resultsPtr, foundPtr->documentIDs) == failure) {
            tsearch_countedset_free(resultsPtr);
            return NULL;
        }
    }

    if (_tsearch_ternarytree_copy_words_from_node(foundPtr->same, resultsPtr) == failure) {
        tsearch_countedset_free(resultsPtr);
        return NULL;
    }

    if (tsearch_countedset_get_count(resultsPtr) == 0) {
        tsearch_countedset_free(resultsPtr);
        resultsPtr = NULL;
    }

    return resultsPtr;
}


tsearch_countedset_ptr tsearch_ternarytree_copy_partial_search_results(const tsearch_ternarytree_ptr ptr,
                                                                       const char *target,
                                                                       const size_t length)
{
    if (ptr == NULL || target == NULL || length == 0) { return NULL; }

    tsearch_countedset_ptr resultsPtr = tsearch_countedset_init();
    if (resultsPtr == NULL) { return  NULL; }

    size_t *prefixTable = NULL;
    if (_tsearch_build_prefix_table(target, length, &prefixTable) == failure) {
        tsearch_countedset_free(resultsPtr);
        return NULL;
    }

    if (_tsearch_ternarytree_find_partial_match(ptr, target, length, prefixTable, 0, resultsPtr) == failure) {
        free(prefixTable);
        tsearch_countedset_free(resultsPtr);
        return NULL;
    }

    free(prefixTable);

    if (tsearch_countedset_get_count(resultsPtr) == 0) {
        tsearch_countedset_free(resultsPtr);
        resultsPtr = NULL;
    }

    return resultsPtr;
}


tsearch_countedset_ptr tsearch_ternarytree_copy_suffix_search_results(const tsearch_ternarytree_ptr ptr,
                                                                      const char *suffix, 
                                                                      const size_t length)
{
    if (ptr == NULL || suffix == NULL || length == 0) { return NULL; }

    tsearch_countedset_ptr resultsPtr = tsearch_countedset_init();
    if (resultsPtr == NULL) { return NULL; }

    if (_tsearch_ternarytree_find_suffix(ptr, suffix, length, resultsPtr) == failure) {
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
    if (outResults == NULL || outLength == NULL) { return failure; }
    *outResults = NULL;
    *outLength = 0;

    if (ptr == NULL) { return failure; }

    tsearch_stringbuf_ptr contentsPtr = tsearch_stringbuf_init();
    if (contentsPtr == NULL) { return failure; }

    int ret = _tsearch_ternarytree_copy_contents(ptr, contentsPtr);
    if (ret == success) {
        *outResults = (char *)tsearch_stringbuf_copy_cstring(contentsPtr);
        if (*outResults == NULL) {
            tsearch_stringbuf_free(contentsPtr);
            return failure;
        }
        *outLength = tsearch_stringbuf_get_len(contentsPtr);
    }

    tsearch_stringbuf_free(contentsPtr);

    return ret;
}


void tsearch_ternarytree_print(tsearch_ternarytree_ptr ptr)
{
    char *results = NULL;
    size_t length = 0;

    printf("<GNETernaryTree, %p>\n", ptr);
    if (tsearch_ternarytree_copy_contents(ptr, &results, &length) == success && results != NULL) {
        printf("%s\n", results);
    } else {
        printf("\n");
    }

    free(results);
    results = NULL;
}


// ------------------------------------------------------------------------------------------
#pragma mark - Private
// ------------------------------------------------------------------------------------------
static bool _tsearch_cstring_is_nonempty(const char *string)
{
    return (string != NULL && string[0] != '\0');
}


tsearch_ternarytree_ptr _tsearch_ternarytree_search(tsearch_ternarytree_ptr ptr, const char *target)
{
    if (!_tsearch_cstring_is_nonempty(target)) { return NULL; }

    const char *cursor = target;
    while (ptr != NULL) {
        char targetCharacter = *cursor;

        if (targetCharacter < ptr->character) {
            ptr = ptr->lower;
        } else if (targetCharacter > ptr->character) {
            ptr = ptr->higher;
        } else {
            if (cursor[1] == '\0') { return ptr; }
            cursor += 1;
            ptr = ptr->same;
        }
    }

    return NULL;
}


result _tsearch_ternarytree_copy_words_from_node(const tsearch_ternarytree_ptr ptr, tsearch_countedset_ptr results)
{
    if (ptr == NULL) { return success; }
    if (results == NULL) { return failure; }

    tsearch_ternarytree_ptr stopParent = ptr->parent;
    tsearch_ternarytree_ptr previous = stopParent;
    tsearch_ternarytree_ptr current = ptr;

    while (current != stopParent) {
        tsearch_ternarytree_ptr next = NULL;
        bool shouldProcess = false;

        if (previous == current->parent) {
            if (current->lower != NULL) { next = current->lower; }
            else { shouldProcess = true; }
        } else if (previous == current->lower) {
            shouldProcess = true;
        } else if (previous == current->same) {
            if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; }
        } else {
            next = current->parent;
        }

        if (shouldProcess == true) {
            if (_tsearch_ternarytree_has_valid_document_ids(current) == true &&
                tsearch_countedset_union(results, current->documentIDs) == failure) {
                return failure;
            }

            if (current->same != NULL) { next = current->same; }
            else if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; }
        }

        previous = current;
        current = next;
    }

    return success;
}


static result _tsearch_build_prefix_table(const char *target, const size_t length, size_t **outTable)
{
    if (target == NULL || length == 0 || outTable == NULL) { return failure; }
    *outTable = NULL;

    size_t byteLength = 0;
    if (_tsearch_size_mul_overflows(length, sizeof(size_t), &byteLength)) {
        return failure;
    }

    size_t *table = calloc(1, byteLength);
    if (table == NULL) { return failure; }

    size_t matched = 0;
    for (size_t i = 1; i < length; i++) {
        while (matched > 0 && target[i] != target[matched]) {
            matched = table[matched - 1];
        }

        if (target[i] == target[matched]) {
            matched += 1;
        }

        table[i] = matched;
    }

    *outTable = table;
    return success;
}


static size_t _tsearch_kmp_next_index(const char *target,
                                      const size_t *prefixTable,
                                      size_t currentIndex,
                                      const char character)
{
    if (target == NULL || prefixTable == NULL) { return 0; }

    while (currentIndex > 0 && character != target[currentIndex]) {
        currentIndex = prefixTable[currentIndex - 1];
    }

    if (character == target[currentIndex]) {
        currentIndex += 1;
    }

    return currentIndex;
}


result _tsearch_ternarytree_find_partial_match(const tsearch_ternarytree_ptr ptr,
                                               const char *target,
                                               const size_t length,
                                               const size_t *prefixTable,
                                               size_t currentIndex,
                                               tsearch_countedset_ptr results)
{
    if (ptr == NULL) { return success; }
    if (target == NULL || prefixTable == NULL || length == 0 || results == NULL) { return failure; }

    _tsearch_partial_search_item *stack = NULL;
    size_t stackCount = 0;
    size_t stackCapacity = 0;

    if (_tsearch_partial_search_stack_push(&stack,
                                           &stackCount,
                                           &stackCapacity,
                                           (_tsearch_partial_search_item){ptr, currentIndex}) == failure) {
        return failure;
    }

    while (stackCount > 0) {
        _tsearch_partial_search_item item = stack[--stackCount];
        tsearch_ternarytree_ptr node = item.node;
        if (node == NULL) { continue; }

        size_t nextIndex = _tsearch_kmp_next_index(target, prefixTable, item.currentIndex, node->character);
        bool shouldSearchSame = true;
        if (nextIndex == length) {
            if (_tsearch_ternarytree_has_valid_document_ids(node) == true &&
                tsearch_countedset_union(results, node->documentIDs) == failure) {
                free(stack);
                return failure;
            }

            if (_tsearch_ternarytree_copy_words_from_node(node->same, results) == failure) {
                free(stack);
                return failure;
            }

            nextIndex = prefixTable[length - 1];
            shouldSearchSame = false;
        }

        if (_tsearch_partial_search_stack_push(&stack,
                                               &stackCount,
                                               &stackCapacity,
                                               (_tsearch_partial_search_item){node->higher, item.currentIndex}) == failure ||
            _tsearch_partial_search_stack_push(&stack,
                                               &stackCount,
                                               &stackCapacity,
                                               (_tsearch_partial_search_item){node->lower, item.currentIndex}) == failure) {
            free(stack);
            return failure;
        }

        if (shouldSearchSame == true &&
            _tsearch_partial_search_stack_push(&stack,
                                               &stackCount,
                                               &stackCapacity,
                                               (_tsearch_partial_search_item){node->same, nextIndex}) == failure) {
            free(stack);
            return failure;
        }
    }

    free(stack);
    return success;
}


result _tsearch_ternarytree_find_suffix(const tsearch_ternarytree_ptr ptr, const char *suffix,
                                        const size_t length, tsearch_countedset_ptr results)
{
    if (ptr == NULL) { return success; }
    if (suffix == NULL || length == 0 || results == NULL) { return failure; }

    tsearch_ternarytree_ptr stopParent = ptr->parent;
    tsearch_ternarytree_ptr previous = stopParent;
    tsearch_ternarytree_ptr current = ptr;

    while (current != stopParent) {
        tsearch_ternarytree_ptr next = NULL;
        bool shouldProcess = false;

        if (previous == current->parent) {
            if (current->lower != NULL) { next = current->lower; }
            else { shouldProcess = true; }
        } else if (previous == current->lower) {
            shouldProcess = true;
        } else if (previous == current->same) {
            if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; }
        } else {
            next = current->parent;
        }

        if (shouldProcess == true) {
            if (_tsearch_ternarytree_has_valid_document_ids(current) == true &&
                current->character == suffix[length - 1]) {
                _tsearch_string_search search = (_tsearch_string_search){suffix, length, length - 1, true};
                if (_tsearch_ternarytree_reverse_search_from_node(current,
                                                                  _tsearch_ternarytree_suffix_search_callback,
                                                                  &search) == failure) {
                    return failure;
                }

                if (search.didMatch == true &&
                    tsearch_countedset_union(results, current->documentIDs) == failure) {
                    return failure;
                }
            }

            if (current->same != NULL) { next = current->same; }
            else if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; }
        }

        previous = current;
        current = next;
    }

    return success;
}


result _tsearch_ternarytree_reverse_search_from_node(tsearch_ternarytree_ptr ptr,
                                                     reverse_search_func callback,
                                                     void *context)
{
    if (ptr == NULL) { return success; }
    if (callback == NULL) { return failure; }

    size_t wordLength = _tsearch_ternarytree_get_word_len(ptr);
    if (wordLength == 0) { return success; }
    size_t characterIndex = wordLength - 1;

    if (callback(ptr->character, characterIndex, context) == callback_stop) { return success; }
    if (characterIndex == 0) { return success; }
    characterIndex -= 1;

    while (ptr != NULL) {
        if (ptr->parent != NULL && ptr->parent->same == ptr) {
            if (callback(ptr->parent->character, characterIndex, context) == callback_stop) { break; }
            if (characterIndex == 0) { break; }
            characterIndex -= 1;
        }
        ptr = ptr->parent;
    }
    return success;
}


result _tsearch_ternarytree_copy_contents(tsearch_ternarytree_ptr ptr, tsearch_stringbuf_ptr contentsPtr)
{
    if (contentsPtr == NULL) { return failure; }
    if (ptr == NULL) { return success; }

    tsearch_ternarytree_ptr stopParent = ptr->parent;
    tsearch_ternarytree_ptr previous = stopParent;
    tsearch_ternarytree_ptr current = ptr;

    while (current != stopParent) {
        tsearch_ternarytree_ptr next = NULL;
        bool shouldProcess = false;

        if (previous == current->parent) {
            if (current->lower != NULL) { next = current->lower; }
            else { shouldProcess = true; }
        } else if (previous == current->lower) {
            shouldProcess = true;
        } else if (previous == current->same) {
            if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; }
        } else {
            next = current->parent;
        }

        if (shouldProcess == true) {
            // We've found the end of a word. Append it to the results array.
            if (_tsearch_ternarytree_has_valid_document_ids(current) == true &&
                _tsearch_ternarytree_copy_word(current, contentsPtr) == failure) {
                return failure;
            }

            if (current->same != NULL) { next = current->same; }
            else if (current->higher != NULL) { next = current->higher; }
            else { next = current->parent; }
        }

        previous = current;
        current = next;
    }

    return success;
}


result _tsearch_ternarytree_copy_word(const tsearch_ternarytree_ptr ptr, const tsearch_stringbuf_ptr contentsPtr)
{
    if (ptr == NULL) { return success; }

    size_t wordLength = 0;
    if (_tsearch_size_add_overflows(_tsearch_ternarytree_get_word_len(ptr), 1, &wordLength)) {
        return failure;
    }

    if (wordLength == 1) { return success; }
    char *word = calloc((wordLength), sizeof(char));
    if (word == NULL) { return failure; }

    word[wordLength - 1] = '\n';

    if (_tsearch_ternarytree_reverse_search_from_node(ptr, _tsearch_ternarytree_copy_word_callback, word) == failure) {
        free(word);
        return failure;
    }

    int ret = tsearch_stringbuf_append_cstring(contentsPtr, word, wordLength);
    free(word);

    return ret;
}


callback_signal _tsearch_ternarytree_suffix_search_callback(const char character,
                                                            const size_t index,
                                                            const void *context)
{
    if (context == NULL) { return callback_stop; }
    _tsearch_string_search *search = (_tsearch_string_search *)context;
    size_t currentIndex = search->currentIndex;
    char target = search->string[currentIndex];
    if (character == target) {
        if (currentIndex > 0) {
            search->currentIndex = currentIndex - 1;
            return callback_continue;
        } else {
            return callback_stop;
        }
    } else {
        search->didMatch = false;
        return callback_stop;
    }
}


callback_signal _tsearch_ternarytree_copy_word_callback(const char character,
                                                        const size_t index,
                                                        const void *context)
{
    if (context == NULL) { return callback_stop; }
    char *word = (char *)context;
    word[index] = character;
    return callback_continue;
}


/// Returns true if the specified pointer is a leaf node (i.e., its lower, same, and
/// higher pointers are NULL), otherwise false.
result _tsearch_ternarytree_is_leaf(const tsearch_ternarytree_ptr ptr)
{
    if (ptr != NULL && ptr->lower == NULL && ptr->same == NULL && ptr->higher == NULL)
    {
        return true;
    }
    return false;
}


/// Returns the length of the beginning at the specified pointer.
/// The length does NOT include the trailing null terminator.
size_t _tsearch_ternarytree_get_word_len(const tsearch_ternarytree_ptr ptr)
{
    if (ptr == NULL || ptr->documentIDs == NULL) { return 0; }
    tsearch_ternarytree_ptr wordPtr = ptr;
    size_t length = 1;

    while (wordPtr != NULL) {
        if (wordPtr->parent != NULL && wordPtr->parent->same == wordPtr) {
            if (_tsearch_size_add_overflows(length, 1, &length)) { return 0; }
        }
        wordPtr = wordPtr->parent;
    }

    return length;
}


/// Return true if the specified node contains one or more document IDs, otherwise false;
bool _tsearch_ternarytree_has_valid_document_ids(const tsearch_ternarytree_ptr ptr)
{
    if (ptr == NULL || ptr->documentIDs == NULL) { return false; }
    return (tsearch_countedset_get_count(ptr->documentIDs) > 0) ? true : false;
}


static result _tsearch_partial_search_stack_push(_tsearch_partial_search_item **stack,
                                                 size_t *count,
                                                 size_t *capacity,
                                                 _tsearch_partial_search_item item)
{
    if (stack == NULL || count == NULL || capacity == NULL) { return failure; }

    if (*count >= *capacity) {
        size_t newCapacity = 0;
        size_t byteLength = 0;

        if (*capacity == 0) {
            newCapacity = 64;
            if (_tsearch_size_mul_overflows(newCapacity, sizeof(_tsearch_partial_search_item), &byteLength)) {
                return failure;
            }
        } else {
            newCapacity = *capacity;
            if (_tsearch_next_buf_len(&newCapacity, sizeof(_tsearch_partial_search_item), &byteLength) == failure) {
                return failure;
            }
        }

        _tsearch_partial_search_item *newStack = realloc(*stack, byteLength);
        if (newStack == NULL) { return failure; }

        *stack = newStack;
        *capacity = newCapacity;
    }

    (*stack)[*count] = item;
    *count += 1;
    return success;
}
