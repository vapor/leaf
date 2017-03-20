import Foundation
import XCTest
@testable import Leaf

class UppercasedTests: XCTestCase {
    static let allTests = [
        ("testUppercased", testUppercased),
        ("testInvalidArgumentCount", testInvalidArgumentCount),
        ("testInvalidType", testInvalidType),
        ("testNil", testNil),
        ("testUnwrapNil", testUnwrapNil),
        ("testUnwrapNilEmpty", testUnwrapNilEmpty),
    ]

    func testUppercased() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #uppercased(name)!")
        let context = Context(["name": "World"])
        let rendered = try stem.render(leaf, with: context).makeString()
        XCTAssert(rendered == "Hello, WORLD!")
    }

    func testInvalidArgumentCount() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #uppercased()!")
        let context = Context([:])
        do {
            _ = try stem.render(leaf, with: context).makeString()
            XCTFail("Expected error")
        } catch Uppercased.Error.expectedOneArgument {}
    }

    func testInvalidType() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #uppercased(name)!")
        let context = Context(["name": ["invalid", "type", "array"]])
        do {
            _ = try stem.render(leaf, with: context).makeString()
            XCTFail("Expected error")
        } catch Uppercased.Error.expectedStringArgument {}
    }

    func testNil() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello #uppercased(name)")
        let context = Context([:])
        let rendered = try stem.render(leaf, with: context).makeString()
        XCTAssert(rendered == "Hello ")
    }

    func testUnwrapNil() throws {
        let leaf = try stem.spawnLeaf(raw: "#uppercased(name) { Hello, #(self)! }")
        let context = Context(["name": "World"])
        let rendered = try stem.render(leaf, with: context).makeString()
        XCTAssert(rendered == "Hello, WORLD!")
    }

    func testUnwrapNilEmpty() throws {
        let leaf = try stem.spawnLeaf(raw: "#uppercased(name) { Hello, #(self)! }")
        let context = Context([:])
        let rendered = try stem.render(leaf, with: context).makeString()
        XCTAssert(rendered == "")
    }
}
