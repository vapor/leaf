import Foundation
import XCTest
@testable import Leaf

class RawTests: XCTestCase {
    static let allTests = [
        ("testRaw", testRaw),
        ("testRawVariable", testRawVariable),
        ("testEscaping", testEscaping),
    ]

    func testRaw() throws {
        let raw = try stem.spawnLeaf(at: "raw")
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

    func testEscaping() throws {
        let expectations = [
            "\\#fooBar()",
            "Hello there\\#fooBar",
        ]

        try expectations.forEach { expectation in
            let raw = try stem.spawnLeaf(raw: expectation)
            let context = Context([:])
            let rendered = try stem.render(raw, with: context).makeString()
            XCTAssertEqual(rendered, expectation)
        }
    }

    func testColumnLine() throws {

    }
}
