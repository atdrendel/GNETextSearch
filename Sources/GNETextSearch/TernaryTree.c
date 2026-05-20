//
//  ternarytree.c
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#include <GNETextSearch/TernaryTree.h>
#include "StringBuffer.h"
#include "GNETextSearchPrivate.h"
#include <stdio.h>
#include <string.h>

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

typedef struct _tsearch_ternarytree_deserialize_item
{
    tsearch_ternarytree_ptr *slot;
    tsearch_ternarytree_ptr parent;
} _tsearch_ternarytree_deserialize_item;

typedef struct _tsearch_ternarytree_writer
{
    void *context;
    result (*write)(void *context, const void *bytes, size_t length);
} _tsearch_ternarytree_writer;

typedef struct _tsearch_ternarytree_reader
{
    void *context;
    result (*read)(void *context, void *bytes, size_t length);
    result (*is_at_end)(void *context);
} _tsearch_ternarytree_reader;

typedef struct _tsearch_ternarytree_memory_writer
{
    uint8_t *bytes;
    size_t length;
    size_t capacity;
} _tsearch_ternarytree_memory_writer;

typedef struct _tsearch_ternarytree_memory_reader
{
    const uint8_t *bytes;
    size_t length;
    size_t position;
} _tsearch_ternarytree_memory_reader;

// ------------------------------------------------------------------------------------------

static bool _tsearch_cstring_is_nonempty(const char *string);
tsearch_ternarytree_ptr _tsearch_ternarytree_search(tsearch_ternarytree_ptr ptr, const char *target);
static result _tsearch_ternarytree_write(const tsearch_ternarytree_ptr ptr, _tsearch_ternarytree_writer *writer);
static result _tsearch_ternarytree_write_header(_tsearch_ternarytree_writer *writer);
static result _tsearch_ternarytree_read_header(_tsearch_ternarytree_reader *reader);
static result _tsearch_ternarytree_write_node(_tsearch_ternarytree_writer *writer, const tsearch_ternarytree_ptr node);
static tsearch_ternarytree_ptr _tsearch_ternarytree_read(_tsearch_ternarytree_reader *reader);
static result _tsearch_ternarytree_read_node(_tsearch_ternarytree_reader *reader,
                                             tsearch_ternarytree_ptr *outNode,
                                             tsearch_ternarytree_ptr parent,
                                             uint8_t *outChildFlags);
static result _tsearch_ternarytree_reader_is_at_end(_tsearch_ternarytree_reader *reader);
static result _tsearch_ternarytree_write_bytes(_tsearch_ternarytree_writer *writer,
                                               const void *bytes,
                                               const size_t length);
static result _tsearch_ternarytree_read_bytes(_tsearch_ternarytree_reader *reader,
                                              void *bytes,
                                              const size_t length);
static result _tsearch_write_u8(_tsearch_ternarytree_writer *writer, const uint8_t value);
static result _tsearch_write_u32_le(_tsearch_ternarytree_writer *writer, const uint32_t value);
static result _tsearch_write_u64_le(_tsearch_ternarytree_writer *writer, const uint64_t value);
static result _tsearch_write_i64_le(_tsearch_ternarytree_writer *writer, const int64_t value);
static result _tsearch_read_u8(_tsearch_ternarytree_reader *reader, uint8_t *outValue);
static result _tsearch_read_u32_le(_tsearch_ternarytree_reader *reader, uint32_t *outValue);
static result _tsearch_read_u64_le(_tsearch_ternarytree_reader *reader, uint64_t *outValue);
static result _tsearch_read_i64_le(_tsearch_ternarytree_reader *reader, int64_t *outValue);
static result _tsearch_ternarytree_file_write(void *context, const void *bytes, size_t length);
static result _tsearch_ternarytree_file_read(void *context, void *bytes, size_t length);
static result _tsearch_ternarytree_file_is_at_end(void *context);
static result _tsearch_ternarytree_memory_write(void *context, const void *bytes, size_t length);
static result _tsearch_ternarytree_memory_read(void *context, void *bytes, size_t length);
static result _tsearch_ternarytree_memory_is_at_end(void *context);
static result _tsearch_u64_to_size(const uint64_t value, size_t *outValue);
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
result _tsearch_ternarytree_find_subsequence_match(const tsearch_ternarytree_ptr ptr,
                                                   const char *target,
                                                   const size_t length,
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
static result _tsearch_ternarytree_node_stack_push(tsearch_ternarytree_ptr **stack,
                                                   size_t *count,
                                                   size_t *capacity,
                                                   tsearch_ternarytree_ptr item);
static result _tsearch_ternarytree_deserialize_stack_push(_tsearch_ternarytree_deserialize_item **stack,
                                                          size_t *count,
                                                          size_t *capacity,
                                                          _tsearch_ternarytree_deserialize_item item);

static const uint8_t _tsearch_ternarytree_file_magic[] = {'G', 'N', 'E', 'T', 'S', 'I', 'D', 'X'};
static const uint32_t _tsearch_ternarytree_file_version = 1;
enum {
    _tsearch_ternarytree_child_lower = 1 << 0,
    _tsearch_ternarytree_child_same = 1 << 1,
    _tsearch_ternarytree_child_higher = 1 << 2,
    _tsearch_ternarytree_child_known_bits =
        (_tsearch_ternarytree_child_lower |
         _tsearch_ternarytree_child_same |
         _tsearch_ternarytree_child_higher)
};

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


tsearch_ternarytree_ptr tsearch_ternarytree_init_from_file(const char *path)
{
    if (!_tsearch_cstring_is_nonempty(path)) { return NULL; }

    FILE *file = fopen(path, "rb");
    if (file == NULL) { return NULL; }

    _tsearch_ternarytree_reader reader = {file, _tsearch_ternarytree_file_read, _tsearch_ternarytree_file_is_at_end};
    tsearch_ternarytree_ptr ptr = _tsearch_ternarytree_read(&reader);
    if (fclose(file) != 0) {
        tsearch_ternarytree_free(ptr);
        return NULL;
    }

    return ptr;
}


tsearch_ternarytree_ptr tsearch_ternarytree_init_from_serialized_bytes(const uint8_t *bytes, const size_t length)
{
    if (bytes == NULL || length == 0) { return NULL; }

    _tsearch_ternarytree_memory_reader memoryReader = {bytes, length, 0};
    _tsearch_ternarytree_reader reader = {
        &memoryReader,
        _tsearch_ternarytree_memory_read,
        _tsearch_ternarytree_memory_is_at_end
    };
    return _tsearch_ternarytree_read(&reader);
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


result tsearch_ternarytree_copy_serialized_bytes(const tsearch_ternarytree_ptr ptr,
                                                uint8_t **outBytes,
                                                size_t *outLength)
{
    if (outBytes != NULL) { *outBytes = NULL; }
    if (outLength != NULL) { *outLength = 0; }
    if (ptr == NULL || outBytes == NULL || outLength == NULL) { return failure; }

    _tsearch_ternarytree_memory_writer memoryWriter = {NULL, 0, 0};
    _tsearch_ternarytree_writer writer = {&memoryWriter, _tsearch_ternarytree_memory_write};
    result ret = _tsearch_ternarytree_write(ptr, &writer);
    if (ret == failure) {
        free(memoryWriter.bytes);
        return failure;
    }

    *outBytes = memoryWriter.bytes;
    *outLength = memoryWriter.length;
    return success;
}


result tsearch_ternarytree_save_to_file(const tsearch_ternarytree_ptr ptr, const char *path)
{
    if (ptr == NULL || !_tsearch_cstring_is_nonempty(path)) { return failure; }

    FILE *file = fopen(path, "wb");
    if (file == NULL) { return failure; }

    _tsearch_ternarytree_writer writer = {file, _tsearch_ternarytree_file_write};
    result ret = _tsearch_ternarytree_write(ptr, &writer);

    if (fclose(file) != 0) { ret = failure; }
    return ret;
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


tsearch_countedset_ptr tsearch_ternarytree_copy_subsequence_search_results(const tsearch_ternarytree_ptr ptr,
                                                                           const char *target,
                                                                           const size_t length)
{
    if (ptr == NULL || target == NULL || length == 0) { return NULL; }

    tsearch_countedset_ptr resultsPtr = tsearch_countedset_init();
    if (resultsPtr == NULL) { return NULL; }

    if (_tsearch_ternarytree_find_subsequence_match(ptr, target, length, 0, resultsPtr) == failure) {
        tsearch_countedset_free(resultsPtr);
        return NULL;
    }

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


static result _tsearch_ternarytree_write(const tsearch_ternarytree_ptr ptr, _tsearch_ternarytree_writer *writer)
{
    if (ptr == NULL || writer == NULL || writer->write == NULL) { return failure; }

    result ret = _tsearch_ternarytree_write_header(writer);

    tsearch_ternarytree_ptr *stack = NULL;
    size_t stackCount = 0;
    size_t stackCapacity = 0;
    if (ret == success) {
        ret = _tsearch_ternarytree_node_stack_push(&stack, &stackCount, &stackCapacity, ptr);
    }

    while (ret == success && stackCount > 0) {
        tsearch_ternarytree_ptr node = stack[--stackCount];
        ret = _tsearch_ternarytree_write_node(writer, node);
        if (ret == failure) { break; }

        if (node->higher != NULL) {
            ret = _tsearch_ternarytree_node_stack_push(&stack, &stackCount, &stackCapacity, node->higher);
            if (ret == failure) { break; }
        }

        if (node->same != NULL) {
            ret = _tsearch_ternarytree_node_stack_push(&stack, &stackCount, &stackCapacity, node->same);
            if (ret == failure) { break; }
        }

        if (node->lower != NULL) {
            ret = _tsearch_ternarytree_node_stack_push(&stack, &stackCount, &stackCapacity, node->lower);
        }
    }

    free(stack);
    return ret;
}


static result _tsearch_ternarytree_write_header(_tsearch_ternarytree_writer *writer)
{
    if (writer == NULL) { return failure; }
    if (_tsearch_ternarytree_write_bytes(writer,
                                         _tsearch_ternarytree_file_magic,
                                         sizeof(_tsearch_ternarytree_file_magic)) == failure) {
        return failure;
    }

    return _tsearch_write_u32_le(writer, _tsearch_ternarytree_file_version);
}


static result _tsearch_ternarytree_read_header(_tsearch_ternarytree_reader *reader)
{
    if (reader == NULL) { return failure; }

    uint8_t magic[sizeof(_tsearch_ternarytree_file_magic)] = {0};
    if (_tsearch_ternarytree_read_bytes(reader, magic, sizeof(magic)) == failure) { return failure; }
    for (size_t i = 0; i < sizeof(_tsearch_ternarytree_file_magic); i++) {
        if (magic[i] != _tsearch_ternarytree_file_magic[i]) { return failure; }
    }

    uint32_t version = 0;
    if (_tsearch_read_u32_le(reader, &version) == failure) { return failure; }
    return (version == _tsearch_ternarytree_file_version) ? success : failure;
}


static result _tsearch_ternarytree_write_node(_tsearch_ternarytree_writer *writer, const tsearch_ternarytree_ptr node)
{
    if (writer == NULL || node == NULL) { return failure; }

    uint8_t childFlags = 0;
    if (node->lower != NULL) { childFlags |= _tsearch_ternarytree_child_lower; }
    if (node->same != NULL) { childFlags |= _tsearch_ternarytree_child_same; }
    if (node->higher != NULL) { childFlags |= _tsearch_ternarytree_child_higher; }

    _tsearch_countedset_serialized_item *items = NULL;
    size_t itemCount = 0;
    if (_tsearch_countedset_copy_items(node->documentIDs, &items, &itemCount) == failure) {
        return failure;
    }

    result ret = _tsearch_write_u8(writer, (uint8_t)node->character);
    if (ret == success) { ret = _tsearch_write_u8(writer, childFlags); }
    if (ret == success) { ret = _tsearch_write_u64_le(writer, (uint64_t)itemCount); }

    for (size_t i = 0; ret == success && i < itemCount; i++) {
        ret = _tsearch_write_i64_le(writer, items[i].integer);
        if (ret == success) { ret = _tsearch_write_u64_le(writer, (uint64_t)items[i].count); }
    }

    free(items);
    return ret;
}


static tsearch_ternarytree_ptr _tsearch_ternarytree_read(_tsearch_ternarytree_reader *reader)
{
    if (_tsearch_ternarytree_read_header(reader) == failure) { return NULL; }

    tsearch_ternarytree_ptr root = NULL;
    _tsearch_ternarytree_deserialize_item *stack = NULL;
    size_t stackCount = 0;
    size_t stackCapacity = 0;

    result ret = _tsearch_ternarytree_deserialize_stack_push(&stack,
                                                             &stackCount,
                                                             &stackCapacity,
                                                             (_tsearch_ternarytree_deserialize_item){&root, NULL});

    while (ret == success && stackCount > 0) {
        _tsearch_ternarytree_deserialize_item item = stack[--stackCount];
        uint8_t childFlags = 0;
        tsearch_ternarytree_ptr node = NULL;
        ret = _tsearch_ternarytree_read_node(reader, &node, item.parent, &childFlags);
        if (ret == failure) { break; }
        *item.slot = node;

        if ((childFlags & _tsearch_ternarytree_child_higher) != 0) {
            ret = _tsearch_ternarytree_deserialize_stack_push(&stack,
                                                              &stackCount,
                                                              &stackCapacity,
                                                              (_tsearch_ternarytree_deserialize_item){&(node->higher), node});
            if (ret == failure) { break; }
        }

        if ((childFlags & _tsearch_ternarytree_child_same) != 0) {
            ret = _tsearch_ternarytree_deserialize_stack_push(&stack,
                                                              &stackCount,
                                                              &stackCapacity,
                                                              (_tsearch_ternarytree_deserialize_item){&(node->same), node});
            if (ret == failure) { break; }
        }

        if ((childFlags & _tsearch_ternarytree_child_lower) != 0) {
            ret = _tsearch_ternarytree_deserialize_stack_push(&stack,
                                                              &stackCount,
                                                              &stackCapacity,
                                                              (_tsearch_ternarytree_deserialize_item){&(node->lower), node});
        }
    }

    if (ret == success) { ret = _tsearch_ternarytree_reader_is_at_end(reader); }

    free(stack);

    if (ret == failure) {
        tsearch_ternarytree_free(root);
        root = NULL;
    }

    return root;
}


static result _tsearch_ternarytree_read_node(_tsearch_ternarytree_reader *reader,
                                             tsearch_ternarytree_ptr *outNode,
                                             tsearch_ternarytree_ptr parent,
                                             uint8_t *outChildFlags)
{
    if (reader == NULL || outNode == NULL || outChildFlags == NULL) { return failure; }
    *outNode = NULL;
    *outChildFlags = 0;

    uint8_t character = 0;
    uint8_t childFlags = 0;
    uint64_t itemCount64 = 0;
    if (_tsearch_read_u8(reader, &character) == failure ||
        _tsearch_read_u8(reader, &childFlags) == failure ||
        _tsearch_read_u64_le(reader, &itemCount64) == failure) {
        return failure;
    }

    if ((childFlags & ~_tsearch_ternarytree_child_known_bits) != 0) {
        return failure;
    }

    size_t itemCount = 0;
    if (_tsearch_u64_to_size(itemCount64, &itemCount) == failure) { return failure; }

    tsearch_ternarytree_ptr node = tsearch_ternarytree_init();
    if (node == NULL) { return failure; }
    node->character = (char)character;
    node->parent = parent;

    if (itemCount > 0) {
        node->documentIDs = tsearch_countedset_init();
        if (node->documentIDs == NULL) {
            tsearch_ternarytree_free(node);
            return failure;
        }
    }

    for (size_t i = 0; i < itemCount; i++) {
        int64_t integer = 0;
        uint64_t count64 = 0;
        size_t count = 0;
        if (_tsearch_read_i64_le(reader, &integer) == failure ||
            _tsearch_read_u64_le(reader, &count64) == failure ||
            _tsearch_u64_to_size(count64, &count) == failure ||
            count == 0 ||
            _tsearch_countedset_add_int_count(node->documentIDs, integer, count) == failure) {
            tsearch_ternarytree_free(node);
            return failure;
        }
    }

    *outNode = node;
    *outChildFlags = childFlags;
    return success;
}


static result _tsearch_ternarytree_reader_is_at_end(_tsearch_ternarytree_reader *reader)
{
    if (reader == NULL || reader->is_at_end == NULL) { return failure; }
    return reader->is_at_end(reader->context);
}


static result _tsearch_ternarytree_write_bytes(_tsearch_ternarytree_writer *writer,
                                               const void *bytes,
                                               const size_t length)
{
    if (writer == NULL || writer->write == NULL) { return failure; }
    if (length > 0 && bytes == NULL) { return failure; }
    if (length == 0) { return success; }

    return writer->write(writer->context, bytes, length);
}


static result _tsearch_ternarytree_read_bytes(_tsearch_ternarytree_reader *reader,
                                              void *bytes,
                                              const size_t length)
{
    if (reader == NULL || reader->read == NULL) { return failure; }
    if (length > 0 && bytes == NULL) { return failure; }
    if (length == 0) { return success; }

    return reader->read(reader->context, bytes, length);
}


static result _tsearch_ternarytree_file_write(void *context, const void *bytes, size_t length)
{
    FILE *file = context;
    if (file == NULL || (length > 0 && bytes == NULL)) { return failure; }
    return (fwrite(bytes, 1, length, file) == length) ? success : failure;
}


static result _tsearch_ternarytree_file_read(void *context, void *bytes, size_t length)
{
    FILE *file = context;
    if (file == NULL || (length > 0 && bytes == NULL)) { return failure; }
    return (fread(bytes, 1, length, file) == length) ? success : failure;
}


static result _tsearch_ternarytree_file_is_at_end(void *context)
{
    FILE *file = context;
    if (file == NULL) { return failure; }
    int character = fgetc(file);
    if (character == EOF) {
        return feof(file) ? success : failure;
    }

    return failure;
}


static result _tsearch_ternarytree_memory_write(void *context, const void *bytes, size_t length)
{
    _tsearch_ternarytree_memory_writer *writer = context;
    if (writer == NULL || (length > 0 && bytes == NULL)) { return failure; }
    if (length == 0) { return success; }

    size_t newLength = 0;
    if (_tsearch_size_add_overflows(writer->length, length, &newLength)) { return failure; }

    if (newLength > writer->capacity) {
        size_t newCapacity = writer->capacity;
        if (newCapacity == 0) { newCapacity = 256; }

        while (newCapacity < newLength) {
            if (_tsearch_size_mul_overflows(newCapacity, 2, &newCapacity)) { return failure; }
        }

        uint8_t *newBytes = realloc(writer->bytes, newCapacity);
        if (newBytes == NULL) { return failure; }

        writer->bytes = newBytes;
        writer->capacity = newCapacity;
    }

    memcpy(writer->bytes + writer->length, bytes, length);
    writer->length = newLength;
    return success;
}


static result _tsearch_ternarytree_memory_read(void *context, void *bytes, size_t length)
{
    _tsearch_ternarytree_memory_reader *reader = context;
    if (reader == NULL || (length > 0 && bytes == NULL)) { return failure; }
    if (length == 0) { return success; }

    if (reader->position > reader->length) { return failure; }
    size_t remainingLength = reader->length - reader->position;
    if (length > remainingLength) { return failure; }
    if (reader->bytes == NULL) { return failure; }

    memcpy(bytes, reader->bytes + reader->position, length);
    reader->position += length;
    return success;
}


static result _tsearch_ternarytree_memory_is_at_end(void *context)
{
    _tsearch_ternarytree_memory_reader *reader = context;
    if (reader == NULL || reader->position > reader->length) { return failure; }
    return (reader->position == reader->length) ? success : failure;
}


static result _tsearch_write_u8(_tsearch_ternarytree_writer *writer, const uint8_t value)
{
    return _tsearch_ternarytree_write_bytes(writer, &value, sizeof(value));
}


static result _tsearch_write_u32_le(_tsearch_ternarytree_writer *writer, const uint32_t value)
{
    uint8_t bytes[4] = {
        (uint8_t)(value & 0xff),
        (uint8_t)((value >> 8) & 0xff),
        (uint8_t)((value >> 16) & 0xff),
        (uint8_t)((value >> 24) & 0xff)
    };
    return _tsearch_ternarytree_write_bytes(writer, bytes, sizeof(bytes));
}


static result _tsearch_write_u64_le(_tsearch_ternarytree_writer *writer, const uint64_t value)
{
    uint8_t bytes[8] = {
        (uint8_t)(value & 0xff),
        (uint8_t)((value >> 8) & 0xff),
        (uint8_t)((value >> 16) & 0xff),
        (uint8_t)((value >> 24) & 0xff),
        (uint8_t)((value >> 32) & 0xff),
        (uint8_t)((value >> 40) & 0xff),
        (uint8_t)((value >> 48) & 0xff),
        (uint8_t)((value >> 56) & 0xff)
    };
    return _tsearch_ternarytree_write_bytes(writer, bytes, sizeof(bytes));
}


static result _tsearch_write_i64_le(_tsearch_ternarytree_writer *writer, const int64_t value)
{
    uint64_t unsignedValue = 0;
    memcpy(&unsignedValue, &value, sizeof(unsignedValue));
    return _tsearch_write_u64_le(writer, unsignedValue);
}


static result _tsearch_read_u8(_tsearch_ternarytree_reader *reader, uint8_t *outValue)
{
    if (outValue == NULL) { return failure; }
    return _tsearch_ternarytree_read_bytes(reader, outValue, sizeof(*outValue));
}


static result _tsearch_read_u32_le(_tsearch_ternarytree_reader *reader, uint32_t *outValue)
{
    if (outValue == NULL) { return failure; }

    uint8_t bytes[4] = {0};
    if (_tsearch_ternarytree_read_bytes(reader, bytes, sizeof(bytes)) == failure) { return failure; }

    *outValue = ((uint32_t)bytes[0] |
                 ((uint32_t)bytes[1] << 8) |
                 ((uint32_t)bytes[2] << 16) |
                 ((uint32_t)bytes[3] << 24));
    return success;
}


static result _tsearch_read_u64_le(_tsearch_ternarytree_reader *reader, uint64_t *outValue)
{
    if (outValue == NULL) { return failure; }

    uint8_t bytes[8] = {0};
    if (_tsearch_ternarytree_read_bytes(reader, bytes, sizeof(bytes)) == failure) { return failure; }

    *outValue = ((uint64_t)bytes[0] |
                 ((uint64_t)bytes[1] << 8) |
                 ((uint64_t)bytes[2] << 16) |
                 ((uint64_t)bytes[3] << 24) |
                 ((uint64_t)bytes[4] << 32) |
                 ((uint64_t)bytes[5] << 40) |
                 ((uint64_t)bytes[6] << 48) |
                 ((uint64_t)bytes[7] << 56));
    return success;
}


static result _tsearch_read_i64_le(_tsearch_ternarytree_reader *reader, int64_t *outValue)
{
    if (outValue == NULL) { return failure; }
    uint64_t unsignedValue = 0;
    if (_tsearch_read_u64_le(reader, &unsignedValue) == failure) { return failure; }
    memcpy(outValue, &unsignedValue, sizeof(*outValue));
    return success;
}


static result _tsearch_u64_to_size(const uint64_t value, size_t *outValue)
{
    if (outValue == NULL || value > SIZE_MAX) { return failure; }
    *outValue = (size_t)value;
    return success;
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


result _tsearch_ternarytree_find_subsequence_match(const tsearch_ternarytree_ptr ptr,
                                                   const char *target,
                                                   const size_t length,
                                                   size_t currentIndex,
                                                   tsearch_countedset_ptr results)
{
    if (ptr == NULL) { return success; }
    if (target == NULL || length == 0 || results == NULL) { return failure; }

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

        size_t nextIndex = item.currentIndex;
        if (nextIndex < length && node->character == target[nextIndex]) {
            nextIndex += 1;
        }

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
        } else if (_tsearch_partial_search_stack_push(&stack,
                                                      &stackCount,
                                                      &stackCapacity,
                                                      (_tsearch_partial_search_item){node->same, nextIndex}) == failure) {
            free(stack);
            return failure;
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
                current->character == suffix[length - 1] &&
                _tsearch_ternarytree_get_word_len(current) >= length) {
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


static result _tsearch_ternarytree_node_stack_push(tsearch_ternarytree_ptr **stack,
                                                   size_t *count,
                                                   size_t *capacity,
                                                   tsearch_ternarytree_ptr item)
{
    if (stack == NULL || count == NULL || capacity == NULL) { return failure; }

    if (*count >= *capacity) {
        size_t newCapacity = 0;
        size_t byteLength = 0;

        if (*capacity == 0) {
            newCapacity = 64;
            if (_tsearch_size_mul_overflows(newCapacity, sizeof(tsearch_ternarytree_ptr), &byteLength)) {
                return failure;
            }
        } else {
            newCapacity = *capacity;
            if (_tsearch_next_buf_len(&newCapacity, sizeof(tsearch_ternarytree_ptr), &byteLength) == failure) {
                return failure;
            }
        }

        tsearch_ternarytree_ptr *newStack = realloc(*stack, byteLength);
        if (newStack == NULL) { return failure; }

        *stack = newStack;
        *capacity = newCapacity;
    }

    (*stack)[*count] = item;
    *count += 1;
    return success;
}


static result _tsearch_ternarytree_deserialize_stack_push(_tsearch_ternarytree_deserialize_item **stack,
                                                          size_t *count,
                                                          size_t *capacity,
                                                          _tsearch_ternarytree_deserialize_item item)
{
    if (stack == NULL || count == NULL || capacity == NULL) { return failure; }
    if (item.slot == NULL) { return failure; }

    if (*count >= *capacity) {
        size_t newCapacity = 0;
        size_t byteLength = 0;

        if (*capacity == 0) {
            newCapacity = 64;
            if (_tsearch_size_mul_overflows(newCapacity, sizeof(_tsearch_ternarytree_deserialize_item), &byteLength)) {
                return failure;
            }
        } else {
            newCapacity = *capacity;
            if (_tsearch_next_buf_len(&newCapacity, sizeof(_tsearch_ternarytree_deserialize_item), &byteLength) == failure) {
                return failure;
            }
        }

        _tsearch_ternarytree_deserialize_item *newStack = realloc(*stack, byteLength);
        if (newStack == NULL) { return failure; }

        *stack = newStack;
        *capacity = newCapacity;
    }

    (*stack)[*count] = item;
    *count += 1;
    return success;
}
