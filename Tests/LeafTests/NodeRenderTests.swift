import Foundation
import XCTest
@testable import Leaf

class NodeRenderTests: XCTestCase {
    static let allTests = [
        ("testRender", testRender),
    ]

    func testRender() throws {
        var node = Node("Hello")
        XCTAssert(try node.rendered() == "Hello".bytes)

        node = .bytes("SomeBytes".bytes)
        XCTAssert(try node.rendered() == "SomeBytes".bytes)

        node = .number(19972)
        XCTAssert(try node.rendered() == "19972".bytes)
        node = .number(-98172)
        XCTAssert(try node.rendered() == "-98172".bytes)
        node = .number(73.655)
        XCTAssert(try node.rendered() == "73.655".bytes)

        node = .object([:])
        XCTAssert(try node.rendered() == [])
        node = .array([])
        XCTAssert(try node.rendered() == [])
        node = .null
        XCTAssert(try node.rendered() == [])

        node = .bool(true)
        XCTAssert(try node.rendered() == "true".bytes)
        node = .bool(false)
        XCTAssert(try node.rendered() == "false".bytes)
    }
}
