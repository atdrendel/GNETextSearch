import Foundation
import XCTest
import GNETextSearch

final class GNETextSearchSwiftImportTests: XCTestCase {
    func testCModuleCanBeImportedAndUsedFromSwift() {
        guard let tree = tsearch_ternarytree_init() else {
            XCTFail("Expected tree allocation to succeed")
            return
        }
        defer { tsearch_ternarytree_free(tree) }

        _ = tsearch_ternarytree_insert(tree, "alpha", 42)

        guard let results = tsearch_ternarytree_copy_search_results(tree, "alpha") else {
            XCTFail("Expected exact search to return results")
            return
        }
        defer { tsearch_countedset_free(results) }

        XCTAssertEqual(tsearch_countedset_get_count(results), 1)
        XCTAssertTrue(tsearch_countedset_contains_int(results, 42))
    }

    func testSerializedBytesCanRoundTripThroughSwiftData() {
        guard let tree = tsearch_ternarytree_init() else {
            XCTFail("Expected tree allocation to succeed")
            return
        }
        defer { tsearch_ternarytree_free(tree) }

        _ = tsearch_ternarytree_insert(tree, "alpha", 42)
        _ = tsearch_ternarytree_insert(tree, "alpha", 42)

        var bytes: UnsafeMutablePointer<UInt8>?
        var length = 0
        XCTAssertEqual(tsearch_ternarytree_copy_serialized_bytes(tree, &bytes, &length), 1)

        guard let rawBytes = bytes else {
            XCTFail("Expected serialized bytes")
            return
        }

        let data = Data(bytesNoCopy: rawBytes, count: length, deallocator: .free)
        bytes = nil

        let loadedTree = data.withUnsafeBytes { rawBuffer in
            tsearch_ternarytree_init_from_serialized_bytes(rawBuffer.bindMemory(to: UInt8.self).baseAddress,
                                                           rawBuffer.count)
        }

        guard let loadedTree else {
            XCTFail("Expected serialized bytes to load")
            return
        }
        defer { tsearch_ternarytree_free(loadedTree) }

        guard let results = tsearch_ternarytree_copy_search_results(loadedTree, "alpha") else {
            XCTFail("Expected exact search to return results")
            return
        }
        defer { tsearch_countedset_free(results) }

        XCTAssertEqual(tsearch_countedset_get_count(results), 1)
        XCTAssertEqual(tsearch_countedset_get_count_for_int(results, 42), 2)
    }
}
