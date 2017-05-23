import Foundation
import XCTest
@testable import Leaf

class RawTests: XCTestCase {
    static let allTests = [
        ("testRaw", testRaw),
        ("testRawVariable", testRawVariable),
        ("testEscaping", testEscaping),
        ("testTagDetection", testTagDetection),
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
        let tests = [
            (input: "\\#fooBar()", expectation: "#fooBar()"),
            (input: "Hello there\\#fooBar", expectation: "Hello there#fooBar"),
        ]

        try tests.forEach { test in
            let raw = try stem.spawnLeaf(raw: test.input)
            let context = Context([:])
            let rendered = try stem.render(raw, with: context).makeString()
            XCTAssertEqual(rendered, test.expectation)
        }
    }

    func testTagDetection() throws {
        let expectations = [
            "<a href=\"#\">"
        ]

        try expectations.forEach { expectation in
            let raw = try stem.spawnLeaf(raw: expectation)
            let context = Context([:])
            let rendered = try stem.render(raw, with: context).makeString()
            XCTAssertEqual(rendered, expectation)
        }
    }
}
