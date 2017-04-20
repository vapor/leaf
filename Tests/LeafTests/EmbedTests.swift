import Foundation
import XCTest
@testable import Leaf

class EmbedTests: XCTestCase {
    static let allTests = [
        ("testBasicEmbed", testBasicEmbed),
        ("testEmbedThrow", testEmbedThrow),
    ]

    func testBasicEmbed() throws {
        let template = try stem.spawnLeaf(at: "embed-base")
        let context = Context(["name": "World"])
        let rendered = try stem.render(template, with: context).makeString()
        let expectation = "Leaf embedded: Hello, World!"
        XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
    }

    func testEmbedThrow() throws {
        do {
            _ = try stem.spawnLeaf(raw: "#embed(invalid-variable)")
            XCTFail("Expected throw")
        } catch Embed.Error.expectedSingleConstant { }
    }
}
