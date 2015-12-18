//
//  GNEMutableString.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 11/11/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef GNEMutableString_h
#define GNEMutableString_h

#include <stdint.h>
#include <stdlib.h>

typedef struct GNEMutableString * GNEMutableStringPtr;

/// Creates an empty mutable string. Returns a pointer to the mutable string if successful, otherwise NULL.
extern GNEMutableStringPtr GNEMutableStringCreate(void);

/// Creates a mutable string containing the specified C char array.
/// Returns a pointer to the mutable string if successful, otherwise NULL.
/// The length parameter refers to the number of chars in cString, but should not include
/// the null terminator.
extern GNEMutableStringPtr GNEMutableStringCreateWithCString(const char *cString, const size_t length);

extern void GNEMutableStringDestroy(GNEMutableStringPtr ptr);

/// Returns the length of the mutable string. The length does not include space for a null terminator.
extern size_t GNEMutableStringGetLength(GNEMutableStringPtr ptr);

/// Returns the char at the specified index of the mutable string.
/// Returns '\0' if the index is past the bounds of the string or if the mutable string is NULL.
extern char GNEMutableStringGetCharAtIndex(GNEMutableStringPtr ptr, size_t index);

/// Appends the specified C char array into the mutable string. Returns 1 if successful, otherwise 0.
/// The length parameter refers to the number of chars in cString, but should not include
/// the null terminator.
extern int GNEMutableStringAppendCString(GNEMutableStringPtr ptr, const char *cString, const size_t length);

/// Returns a null-terminated char representation of the mutable string's contents.
/// The returned char array must be freed by the caller.
extern const char * GNEMutableStringCopyContents(GNEMutableStringPtr ptr);

extern void GNEMutableStringPrint(GNEMutableStringPtr ptr);

#endif /* GNEMutableString_h */
