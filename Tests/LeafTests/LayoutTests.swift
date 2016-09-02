import Foundation
import XCTest
@testable import Leaf

class LayoutTests: XCTestCase {
    static let allTests = [
        ("testBasicLayout", testBasicLayout),
        ("testBasicLayoutFallback", testBasicLayoutFallback),
        ("testSimpleEmbed", testSimpleEmbed),
        ("testLayoutEmbedMix", testLayoutEmbedMix),
    ]

    func testBasicLayout() throws {
        let leaf = try stem.spawnLeaf(named: "basic-extension")
        let rendered = try stem.render(leaf, with: Context(["name": "World"])).string
        let expectation = "Aloha, World!"
        XCTAssertEqual(rendered, expectation)
    }
    func testBasicLayoutFallback() throws {
        // no export
        let extensionNoExport = "#extend(\"basic-extendable\")"
        let leaf = try stem.spawnLeaf(raw: extensionNoExport)
        let rendered = try stem.render(leaf, with: Context(["name": "World"])).string
        let expectation = "Hello, World!"
        XCTAssertEqual(rendered, expectation)
    }

    func testSimpleEmbed() throws {
        let simple = "I'm a header! #embed(\"template-basic-raw\")"
        let leaf = try stem.spawnLeaf(raw: simple)
        let rendered = try stem.render(leaf, with: Context([:])).string
        let expectation = "I'm a header! Hello, World!"
        XCTAssertEqual(rendered, expectation)
    }

    func testLayoutEmbedMix() throws {
        var extend = "#extend(\"base\")\n"
        extend += "#export(\"header\") { I'm a header! #embed(\"template-basic-raw\") }"
        let extendLeaf = try stem.spawnLeaf(raw: extend)

        let rendered = try stem.render(extendLeaf, with: Context([:])).string
        let expectation = "I'm a header! Hello, World!"
        XCTAssertEqual(rendered, expectation)
    }
}
