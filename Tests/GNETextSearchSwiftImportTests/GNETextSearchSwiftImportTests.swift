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
}
