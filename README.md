# GNETextSearch
Full-text search engine using ternary trees written in C.

# Swift Package Manager

Add GNETextSearch to a Swift package with:

```swift
dependencies: [
    .package(url: "https://github.com/atdrendel/GNETextSearch.git", from: "2.0.0"),
]
```

Then add the C library product to a target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "GNETextSearch", package: "GNETextSearch"),
    ]
)
```

C clients can include the public umbrella header:

```c
#include <GNETextSearch/GNETextSearch.h>
```

Swift code can import the C module directly through the package's explicit module map:

```swift
import GNETextSearch

let tree = tsearch_ternarytree_init()
_ = tsearch_ternarytree_insert(tree, "GNETextSearch", 1)
```

# Package Layout

```text
Sources/
  GNETextSearch/
    include/
      module.modulemap
      GNETextSearch/
        GNETextSearch.h
        CountedSet.h
        TernaryTree.h
        Types.h
    CountedSet.c
    StringBuffer.c
    StringBuffer.h
    TernaryTree.c
    Tokenize.c
    Tokenize.h
    UTF8Utilities.h
    GNETextSearchPrivate.h
Tests/
  GNETextSearchCTests/
    countedset_tests.m
    stringbuf_tests.m
    ternarytree_tests.m
    tokenize_tests.m
    Resources/
  GNETextSearchSwiftImportTests/
```

The package is a C library. The explicit `module.modulemap` makes that C API importable from
Swift without adding a Swift wrapper layer. The public surface is limited to the ternary tree,
counted-set, and shared type headers under `Sources/GNETextSearch/include/GNETextSearch`.
Tokenizer and string-buffer headers remain implementation details.

# License

Copyright (c) 2026, Anthony Drendel
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
