import Foundation
import XCTest
@testable import Leaf

class ExpressionTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic),
    ]
    
    func testBasic() throws {
        let leaf = try! stem.spawnLeaf(raw: "Hello, #if(:\"1\" == \"1\") { World! } ##else() { noooooo }")
        let context = Context([:])
        let rendered = try! stem.render(leaf, with: context).makeString()
        XCTAssert(rendered == "Hello, World!")
    }
}
