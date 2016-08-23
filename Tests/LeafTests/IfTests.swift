import Foundation
import XCTest
@testable import Leaf

class IfTests: XCTestCase {
    static let allTests = [
        ("testBasicIf", testBasicIf),
        ("testBasicIfFail", testBasicIfFail),
        ("testBasicIfElse", testBasicIfElse),
        ("testNestedIfElse", testNestedIfElse),
        ("testIfThrow", testIfThrow),
    ]

    func testBasicIf() throws {
        let template = try stem.spawnLeaf(named: "basic-if-test")

        let context = try Node(node: ["say-hello": true])
        let loadable = Context(context)
        let rendered = try stem.render(template, with: loadable).string
        let expectation = "Hello, there!"
        XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
    }

    func testBasicIfFail() throws {
        let template = try stem.spawnLeaf(named: "basic-if-test")

        let context = try Node(node: ["say-hello": false])
        let loadable = Context(context)
        let rendered = try stem.render(template, with: loadable).string
        let expectation = ""
        XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
    }

    func testBasicIfElse() throws {
        let template = try stem.spawnLeaf(named: "basic-if-else")

        let helloContext = try Node(node: [
            "entering": true,
            "friend-name": "World"
            ])
        let hello = Context(helloContext)
        let renderedHello = try stem.render(template, with: hello).string
        let expectedHello = "Hello, World!"
        XCTAssert(renderedHello == expectedHello, "have: \(renderedHello) want: \(expectedHello)")

        let goodbyeContext = try Node(node: [
            "entering": false,
            "friend-name": "World"
            ])
        let goodbye = Context(goodbyeContext)
        let renderedGoodbye = try stem.render(template, with: goodbye).string
        let expectedGoodbye = "Goodbye, World!"
        XCTAssert(renderedGoodbye == expectedGoodbye, "have: \(renderedGoodbye) want: \(expectedGoodbye)")
    }

    func testNestedIfElse() throws {
        let template = try stem.spawnLeaf(named: "nested-if-else")
        let expectations: [(input: Node, expectation: String)] = [
            (input: ["a": true], expectation: "Got a."),
            (input: ["b": true], expectation: "Got b."),
            (input: ["c": true], expectation: "Got c."),
            (input: ["d": true], expectation: "Got d."),
            (input: [:], expectation: "Got e.")
        ]

        try expectations.forEach { input, expectation in
            let context = Context(input)
            let rendered = try stem.render(template, with: context).string
            XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
        }
    }

    func testIfThrow() throws {
        let leaf = try stem.spawnLeaf(raw: "#if(too, many, arguments) { }")
        let context = Context([:])
        do {
            _ = try stem.render(leaf, with: context)
            XCTFail("should throw")
        } catch If.Error.expectedSingleArgument {}
    }
}
