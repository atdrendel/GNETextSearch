//
//  utf8_utils.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 1/9/16.
//  Copyright © 2016 Gone East LLC. All rights reserved.
//

#ifndef GNEUnicodeWordBoundary_h
#define GNEUnicodeWordBoundary_h

#include "GNETextSearchPublic.h"

#ifndef TSEARCH_INLINE
    #if defined(_MSC_VER) && !defined(__cplusplus)
        #define TSEARCH_INLINE __inline
    #else
        #define TSEARCH_INLINE static inline
    #endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

TSEARCH_INLINE bool utf8_isSpace(uint32_t character)
{
    return (character == 0x0020 || character == 0x3000 || (character >= 0x2002 && character <= 0x200B)) ? true : false;
}


TSEARCH_INLINE bool utf8_isTab(uint32_t character)
{
    return (character == 0x0009) ? true : false;
}


TSEARCH_INLINE bool utf8_isNewline(uint32_t character)
{
    return (character == 0x000A || character == 0x000D) ? true : false;
}


TSEARCH_INLINE bool utf8_isWhitespace(uint32_t character)
{
    return (utf8_isSpace(character) || utf8_isNewline(character) || utf8_isTab(character)) ? true : false;
}


static inline bool utf8_isBreak(uint32_t character)
{
    return utf8_isWhitespace(character);
}

#ifdef __cplusplus
}
#endif


#endif /* GNEUnicodeWordBoundary_h */
