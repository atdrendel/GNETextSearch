//
//  GNETernaryTree.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef GNETernaryTree_h
#define GNETernaryTree_h

#include "countedset.h"
#include "GNETextSearchPublic.h"

typedef struct GNETernaryTreeNode *GNETernaryTreePtr;

extern GNETernaryTreePtr GNETernaryTreeCreate(void);
extern void GNETernaryTreeDestroy(GNETernaryTreePtr ptr);
extern GNETernaryTreePtr GNETernaryTreeInsert(GNETernaryTreePtr ptr, const char *newCharacter, GNEInteger documentID);
extern result GNETernaryTreeRemove(GNETernaryTreePtr ptr, GNEInteger documentID);

/// Returns a GNEIntegerCountedSet with the IDs of the documents containing the target. The caller is
/// responsible for calling tsearch_countedset_free().
extern tsearch_countedset_ptr GNETernaryTreeCopyResultsForSearch(GNETernaryTreePtr ptr, const char *target);

/// Returns a tsearch_countedset_ptr with the IDs of the documents containing the target prefix. The caller
/// is responsible for calling tsearch_countedset_free().
extern tsearch_countedset_ptr GNETernaryTreeCopyResultsForPrefixSearch(GNETernaryTreePtr ptr, const char *prefix);

/// Copies all words contained in the tree into outResults (which much be freed by the caller).
extern result GNETernaryTreeCopyContents(GNETernaryTreePtr ptr, char **outResults, size_t *outLength);

extern void GNETernaryTreePrint(GNETernaryTreePtr ptr);

#endif
