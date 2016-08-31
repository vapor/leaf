import Foundation
import XCTest
@testable import Leaf

class FileLoadTests: XCTestCase {
    static let allTests = [
        ("testLoadRawBytes", testLoadRawBytes),
    ]

    func testLoadRawBytes() throws {
        let leaf = try stem.spawnLeaf(named: "random-file.any")
        XCTAssert(Array(leaf.components).count == 1)

        let rendered = try stem.render(leaf, with: Context([])).string
        // tags are not parsed in non-leaf document
        let expectation = "This file #(won't) be #rendered() {}\n"
        XCTAssertEqual(rendered, expectation)

        // test cache
        _ = try stem.spawnLeaf(named: "random-file.any")
    }
}
