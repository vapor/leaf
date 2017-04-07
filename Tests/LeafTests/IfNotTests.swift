import Foundation
import XCTest
@testable import Leaf

class IfNotTests: XCTestCase {
    static let allTests = [
        ("testBasicIfNot", testBasicIfNot),
        ("testBasicIfNotFail", testBasicIfNotFail),
        ("testBasicIfNotElse", testBasicIfNotElse),
        ("testNestedIfNotElse", testNestedIfNotElse),
        ("testIfNotThrow", testIfNotThrow),
        ("testIfNotEmptyString", testIfNotEmptyString),
    ]

    func testBasicIfNot() throws {
        let template = try stem.spawnLeaf(named: "basic-ifnot-test")

        let context = try Node(node: ["say-hello": false])
        let loadable = Context(context)
        let rendered = try stem.render(template, with: loadable).makeString()
        let expectation = "Hello, there!"
        XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
    }

    func testBasicIfNotFail() throws {
        let template = try stem.spawnLeaf(named: "basic-ifnot-test")

        let context = try Node(node: ["say-hello": true])
        let loadable = Context(context)
        let rendered = try stem.render(template, with: loadable).makeString()
        let expectation = ""
        XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
    }

    func testBasicIfNotElse() throws {
        let template = try stem.spawnLeaf(named: "basic-ifnot-else")

        let helloContext = try Node(node: [
            "entering": false,
            "friend-name": "World"
            ])
        let hello = Context(helloContext)
        let renderedHello = try stem.render(template, with: hello).makeString()
        let expectedHello = "Hello, World!"
        XCTAssert(renderedHello == expectedHello, "have: \(renderedHello) want: \(expectedHello)")

        let goodbyeContext = try Node(node: [
            "entering": false,
            "friend-name": "World"
            ])
        let goodbye = Context(goodbyeContext)
        let renderedGoodbye = try stem.render(template, with: goodbye).makeString()
        let expectedGoodbye = "Hello, World!"
        XCTAssert(renderedGoodbye == expectedGoodbye, "have: \(renderedGoodbye) want: \(expectedGoodbye)")
    }

    func testNestedIfNotElse() throws {
        let template = try stem.spawnLeaf(named: "nested-ifnot-else")
        let expectations: [(input: Node, expectation: String)] = [
            (input: ["a": false], expectation: "Got a."),
            (input: ["b": false], expectation: "Got b."),
            (input: ["c": false], expectation: "Got c."),
            (input: ["d": false], expectation: "Got d."),
            (input: [:], expectation: "Got e.")
        ]

        try expectations.forEach { input, expectation in
            let context = Context(input)
            let rendered = try stem.render(template, with: context).makeString()
            XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
        }
    }

    func testIfNotThrow() throws {
        let leaf = try stem.spawnLeaf(raw: "#ifnot(too, many, arguments) { }")
        let context = Context([:])
        do {
            _ = try stem.render(leaf, with: context)
            XCTFail("should throw")
        } catch If.Error.expectedSingleArgument {}
    }

    func testIfNotEmptyString() throws {
        let template = try stem.spawnLeaf(named: "ifnot-empty-string-test")
        do {
            let context = try Node(node: ["name": ""])
            let loadable = Context(context)
            let rendered = try stem.render(template, with: loadable).makeString()
            let expectation = "Hello, there!"
            XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
        }
        do {
            let context = try Node(node: ["name": "name"])
            let loadable = Context(context)
            let rendered = try stem.render(template, with: loadable).makeString()
            let expectation = ""
            XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
        }
    }
}
