//
//  GNETextSearch.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#if defined(__has_include)
    #if __has_include(<GNETextSearch/ternarytree.h>)
        #import <GNETextSearch/ternarytree.h>
    #else
        #import "Tree/ternarytree.h"
    #endif
    #if __has_include(<GNETextSearch/countedset.h>)
        #import <GNETextSearch/countedset.h>
    #else
        #import "Set/countedset.h"
    #endif
#else
    #import "Tree/ternarytree.h"
    #import "Set/countedset.h"
#endif
