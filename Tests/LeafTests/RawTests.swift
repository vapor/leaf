import Foundation
import XCTest
@testable import Leaf

class RawTests: XCTestCase {
    func testRaw() throws {
        let raw = try stem.spawnLeaf(named: "raw")
        let rendered = try stem.render(raw, with: Context([:])).string
        let expectation = "Everything stays ^#@$&"
        XCTAssertEqual(rendered, expectation)
    }
}
