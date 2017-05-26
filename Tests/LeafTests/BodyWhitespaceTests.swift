import Foundation
import XCTest
@testable import Leaf

class BodyWhitespaceTests: XCTestCase {
    
    static let allTests = [
        ("testAdditionalWhitespace", testAdditionalWhitespace),
        ("testNoWhitespace", testNoWhitespace)
    ]
    
    func testAdditionalWhitespace() throws {
        let leaf = try stem.spawnLeaf(at: "variable-body-whitespace")
        let rendered = try stem.render(leaf, with: Context(["name": "World"])).makeString()
        let expectation = "Aloha, World!"
        XCTAssertEqual(rendered, expectation)
    }
    
    func testNoWhitespace() throws {
        let leaf = try stem.spawnLeaf(at: "no-body-whitespace")
        let rendered = try stem.render(leaf, with: Context(["name": "World"])).makeString()
        let expectation = "Aloha, World!"
        XCTAssertEqual(rendered, expectation)
    }

}
