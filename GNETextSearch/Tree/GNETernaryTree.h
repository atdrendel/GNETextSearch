//
//  GNETernaryTree.h
//  GNETextSearch
//
//  Created by Anthony Drendel on 8/31/15.
//  Copyright © 2015 Gone East LLC. All rights reserved.
//

#ifndef GNETernaryTree_h
#define GNETernaryTree_h

#include "GNEIntegerArray.h"
#include "GNECommon.h"

typedef struct GNETernaryTreeNode *GNETernaryTreePtr;
typedef struct GNETernaryTreeNode GNETernaryTreeNode;

extern void GNETernaryTreeDestroy(GNETernaryTreePtr ptr);
extern GNETernaryTreePtr GNETernaryTreeInsert(GNETernaryTreePtr ptr, const char *newCharacter, GNEInteger documentID);
/// Returns a pointer to the node corresponding to the 
extern GNEIntegerArrayPtr GNETernaryTreeSearch(GNETernaryTreePtr ptr, const char *target);
/// Copies all words contained in the tree into outResults (which much be freed by the caller).
extern int GNETernaryTreeCopyContents(GNETernaryTreePtr ptr, char **outResults, size_t *outLength);

#endif
