//
//  GNEUnicodeWordBoundary.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 1/9/16.
//  Copyright © 2016 Gone East LLC. All rights reserved.
//

#ifndef GNEUnicodeWordBoundary_h
#define GNEUnicodeWordBoundary_h

#include "GNETextSearchPublic.h"


static inline bool utf8_isSpace(uint32_t character)
{
    return (character == 0x0020 || character == 0x3000 || (character >= 0x2002 && character <= 0x200B)) ? true : false;
}


static inline bool utf8_isTab(uint32_t character)
{
    return (character == 0x0009) ? true : false;
}


static inline bool utf8_isNewline(uint32_t character)
{
    return (character == 0x000A || character == 0x000D) ? true : false;
}


static inline bool utf8_isWhitespace(uint32_t character)
{
    return (utf8_isSpace(character) || utf8_isNewline(character) || utf8_isTab(character)) ? true : false;
}


static inline bool utf8_isBreak(uint32_t character)
{
    return utf8_isWhitespace(character);
}


#endif /* GNEUnicodeWordBoundary_h */
