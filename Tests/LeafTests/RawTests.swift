import Foundation
import XCTest
@testable import Leaf

class RawTests: XCTestCase {
    static let allTests = [
        ("testRaw", testRaw),
    ]

    func testRaw() throws {
        let raw = try stem.spawnLeaf(named: "raw")
        let rendered = try stem.render(raw, with: Context([:])).makeString()
        let expectation = "Everything stays ##@$&"
        XCTAssertEqual(rendered, expectation)
    }

    func testRawVariable() throws {
        let raw = try stem.spawnLeaf(raw: "Hello, #raw(unescaped)!")
        let context = Context(["unescaped": "<b>World</b>"])
        let rendered = try stem.render(raw, with: context).makeString()
        let expectation = "Hello, <b>World</b>!"
        XCTAssertEqual(rendered, expectation)
    }
}
