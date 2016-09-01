import Foundation
import XCTest
@testable import Leaf

class TagTemplateTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic),
        ("testEquatable", testEquatable),
        ("testChainFail", testChainFail),
        ("testMissingOpenParens", testMissingOpenParens),
        ("testEquatableComponents", testEquatableComponents),
    ]

    func testBasic() throws {
        let raw = "*(name) { *uppercased(self) }"
        // let raw = "*uppercased(name)"
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["name": "hi"])
        let rendered = try stem.render(template, with: context).string
        let expectation = "HI"
        XCTAssert(rendered == expectation)
    }

    func testEquatable() throws {
        let lhs = try TagTemplate(
            name: "Foo",
            parameters: [.constant(value: "Hello!")],
            body: "Just some body, *if(variable) { if } **else { else *(variable) { *(self) exists }"
        )
        let rhs = try TagTemplate(
            name: "Foo",
            parameters: [.constant(value: "Hello!")],
            body: "Just some body, *if(variable) { if } **else { else *(variable) { *(self) exists }"
        )

        XCTAssert(lhs == rhs)
        XCTAssert(lhs.description == rhs.description)

        let other = try TagTemplate(
            name: "Foo",
            parameters: [.constant(value: "Hello!")],
            body: "Different"
        )

        XCTAssertFalse(other == lhs)
        XCTAssertFalse(other == rhs)
    }

    func testEquatableComponents() throws {
        let lhs = Leaf.Component.raw("raw".bytes)
        let rhs = Leaf.Component.chain([])
        XCTAssertNotEqual(lhs, rhs)
    }

    func testChainFail() throws {
        do {
            _ = try stem.spawnLeaf(raw: "**else() {}")
            XCTFail()
        } catch ParseError.expectedLeadingTemplate {}


        do {
            _ = try stem.spawnLeaf(raw: "Different component **else() {}")
            XCTFail()
        } catch ParseError.expectedLeadingTemplate {}
    }

    func testMissingOpenParens() throws {
        do {
            _ = try stem.spawnLeaf(raw: "*invalid-tag {}")
            XCTFail()
        } catch ParseError.expectedOpenParenthesis {}
    }
}
