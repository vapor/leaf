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
        let raw = "#(name) { #uppercased(self) }"
        // let raw = "#uppercased(name)"
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["name": "hi"])
        let rendered = try stem.render(template, with: context).string
        let expectation = "HI"
        XCTAssert(rendered == expectation)
    }

    func testEquatable() throws {
        let lhsb = try stem.spawnLeaf(raw: "Just some body, #if(variable) { if } ##else() { else #(variable) { #(self) exists } }")
        let lhs = TagTemplate(
            name: "Foo",
            parameters: [.constant(value: "Hello!")],
            body: lhsb
        )

        let rhsb = try stem.spawnLeaf(raw: "Just some body, #if(variable) { if } ##else() { else #(variable) { #(self) exists } }")
        let rhs = TagTemplate(
            name: "Foo",
            parameters: [.constant(value: "Hello!")],
            body: rhsb
        )

        XCTAssert(lhs == rhs)
        XCTAssert(lhs.description == rhs.description)

        let otherb = try stem.spawnLeaf(raw: "Different")
        let other = TagTemplate(
            name: "Foo",
            parameters: [.constant(value: "Hello!")],
            body: otherb
        )

        XCTAssertFalse(other == lhs)
        XCTAssertFalse(other == rhs)
    }

    func testEquatableComponents() throws {
        let lhs = Leaf.Component.raw("raw".makeBytes())
        let rhs = Leaf.Component.chain([])
        XCTAssertNotEqual(lhs, rhs)
    }

    func testChainFail() throws {
        do {
            _ = try stem.spawnLeaf(raw: "##else() {}")
            XCTFail()
        } catch ParseError.expectedLeadingTemplate {}


        do {
            _ = try stem.spawnLeaf(raw: "Different component ##else() {}")
            XCTFail()
        } catch ParseError.expectedLeadingTemplate {}
    }

    func testMissingOpenParens() throws {
        do {
            _ = try stem.spawnLeaf(raw: "#invalid-tag {}")
            XCTFail()
        } catch ParseError.expectedOpenParenthesis {}
    }
}
