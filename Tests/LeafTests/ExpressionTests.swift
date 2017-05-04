import Foundation
import XCTest
@testable import Leaf

class ExpressionTests: XCTestCase {
    func testBasic() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #(an expression)!")
        let context = Context([:])
        let rendered = try stem.render(leaf, with: context).makeString()
        XCTAssert(rendered == "Hello, expression!")
    }
}
