// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GNETextSearch",
    products: [
        .library(
            name: "GNETextSearch",
            targets: ["GNETextSearch"]
        ),
    ],
    targets: [
        .target(
            name: "GNETextSearch",
            path: "Sources/GNETextSearch",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
            ]
        ),
        .testTarget(
            name: "GNETextSearchCTests",
            dependencies: ["GNETextSearch"],
            path: "Tests/GNETextSearchCTests",
            resources: [
                .process("Resources"),
            ],
            cSettings: [
                .headerSearchPath("../../Sources/GNETextSearch"),
            ]
        ),
        .testTarget(
            name: "GNETextSearchSwiftImportTests",
            dependencies: ["GNETextSearch"],
            path: "Tests/GNETextSearchSwiftImportTests"
        ),
    ]
)
