import Foundation
import XCTest
@testable import Leaf

class VariableTests: XCTestCase {
    static let allTests = [
        ("testVariable", testVariable),
        ("testVariableThrows", testVariableThrows),
        ("testVariableEscape", testVariableEscape),
        ("testConstant", testConstant),
        ("testCarriageReturn", testCarriageReturn),
    ]

    func testVariable() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #(name)!")
        let context = Context(["name": "World"])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "Hello, World!")
    }

    func testVariableThrows() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #(name, location)!")
        let context = Context([:])
        do {
            _ = try stem.render(leaf, with: context).string
            XCTFail("Expected error")
        } catch Variable.Error.expectedOneArgument { }
    }

    func testVariableEscape() throws {
        // All tokens are parsed, this tests an escape mechanism to introduce explicit.
        let leaf = try stem.spawnLeaf(raw: "#()#(hashtag)!")
        let context = Context(["hashtag": "leafRules"])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "#leafRules!")
    }

    func testConstant() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #(\"World\")!")
        let context = Context([:])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "Hello, World!")
    }

    func testCarriageReturn() throws {
        let leaf = try stem.spawnLeaf(raw: "This thing: #(content)")
        let context = Context(["content": "\r\n\"/\""])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "This thing: \r\n&quot;/&quot;")
    }
}
