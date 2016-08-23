import Foundation
import XCTest
@testable import Leaf

class IncludeTests: XCTestCase {
    static let allTests = [
        ("testBasicInclude", testBasicInclude),
        ("testIncludeThrow", testIncludeThrow),
    ]

    func testBasicInclude() throws {
        let stem = Stem()
        let template = try stem.spawnLeaf(named: "/include-base")
        // let template = try spawnLeaf(named: "include-base")
        let context = Context(["name": "World"])
        let rendered = try stem.render(template, with: context).string
        let expectation = "Leaf included: Hello, World!"
        XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
    }

    func testIncludeThrow() throws {
        do {
            _ = try stem.spawnLeaf(raw: "#include(invalid-variable)")
            XCTFail("Expected throw")
        } catch Include.Error.expectedSingleConstant { }
    }
}
