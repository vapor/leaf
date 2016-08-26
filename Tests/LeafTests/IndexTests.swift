import Foundation
import XCTest
@testable import Leaf

class IndexTests: XCTestCase {
    static let allTests = [
        ("testOverrideRequired", testOverrideRequired),
        ("testBasicIndex", testBasicIndex),
        ("testOutOfBounds", testOutOfBounds)
    ]

    func testOverrideRequired() throws {
        let basic = BasicTag(name: "fail")
        stem.register(basic)
        defer { stem.remove(basic) }

        let template = try stem.spawnLeaf(raw: "This should #fail()")
        let context = Context([])
        do {
            _ = try stem.render(template, with: context)
            XCTFail()
        } catch BasicTag.Error.overrideRequired {}
    }

    func testBasicIndex() throws {
        let template = try stem.spawnLeaf(raw: "Hello, #index(friends, idx)!")
        let context = Context(["friends": ["Joe", "Jan", "Jay", "Jen"], "idx": 3])
        let rendered = try stem.render(template, with: context).string
        let expectation = "Hello, Jen!"
        XCTAssertEqual(rendered, expectation)
    }

    func testOutOfBounds() throws {
        let template = try stem.spawnLeaf(raw: "Hello, #index(friends, idx)!")
        let context = Context(["friends": [], "idx": 3])
        let rendered = try stem.render(template, with: context).string
        let expectation = "Hello, !"
        XCTAssertEqual(rendered, expectation)
    }
}
