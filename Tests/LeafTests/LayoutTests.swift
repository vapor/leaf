import Foundation
import XCTest
@testable import Leaf

class LayoutTests: XCTestCase {
    func testBasicLayout() throws {
        let leaf = try stem.spawnLeaf(named: "basic-extension")
        let rendered = try stem.render(leaf, with: Context(["name": "World"])).string
        let expectation = "Aloha, World!"
        XCTAssertEqual(rendered, expectation)
    }
    func testBasicLayoutFallback() throws {
        // no export
        let extensionNoExport = "*extend(\"basic-extendable\")"
        let leaf = try stem.spawnLeaf(raw: extensionNoExport)
        let rendered = try stem.render(leaf, with: Context(["name": "World"])).string
        let expectation = "Hello, World!"
        XCTAssertEqual(rendered, expectation)
    }
}
