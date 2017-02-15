import Foundation
import XCTest
@testable import Leaf

class NodeRenderTests: XCTestCase {
    static let allTests = [
        ("testRender", testRender),
    ]

    func testRender() throws {
        var node = Node("Hello")
        XCTAssert(try node.rendered() == "Hello".makeBytes())

        node = .bytes("SomeBytes".makeBytes())
        XCTAssert(try node.rendered() == "SomeBytes".makeBytes())

        node = .number(19972)
        XCTAssert(try node.rendered() == "19972".makeBytes())
        node = .number(-98172)
        XCTAssert(try node.rendered() == "-98172".makeBytes())
        node = .number(73.655)
        XCTAssert(try node.rendered() == "73.655".makeBytes())

        node = .object([:])
        XCTAssert(try node.rendered() == [])
        node = .array([])
        XCTAssert(try node.rendered() == [])
        node = .null
        XCTAssert(try node.rendered() == [])

        node = .bool(true)
        XCTAssert(try node.rendered() == "true".makeBytes())
        node = .bool(false)
        XCTAssert(try node.rendered() == "false".makeBytes())
    }
}
