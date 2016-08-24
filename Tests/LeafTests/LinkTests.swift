import Foundation
import XCTest
@testable import Leaf

class LinkTests: XCTestCase {
    static let allTests = [
        ("testArray", testArray),
        ("testList", testList),
        ("testIterateArray", testIterateArray),
        ("testIterateList", testIterateList),
        ("testChild", testChild),
        ("testParent", testParent),
        ("testTipAndTail", testTipAndTail),
    ]

    func testArray() {
        var array: [Node] = []
        measure {
            (1...500).forEach { _ in
                array.insert(["self": "..."], at: 0)
                defer { array.removeFirst() }
            }
        }
    }

    func testList() {
        var list = List<Node>()
        measure {
            (1...500).forEach { _ in
                list.insertAtTip(["self": "..."])
                defer { list.removeTip() }
            }
        }
    }

    func testIterateArray() {
        let array = [Int](repeating: 0, count: 100)
        measure {
            (1...5000).forEach { _ in
                array.forEach { _ in }
            }
        }
    }

    func testIterateList() {
        let array = [Int](repeating: 0, count: 100)
        let list = List(array)
        measure {
            (1...5000).forEach { _ in
                list.forEach { _ in }
            }
        }
        list.removeTail()
        XCTAssert([Int](list) == [Int](repeating: 0, count: 99))
    }

    func testChild() {
        let link = Link(0)
        link.addChild(Link(1))
        XCTAssert(link.child?.value == 1)
        link.addChild(Link(2))
        XCTAssert(link.child?.value == 2)
        XCTAssert([Int](link) == [0, 2])
        link.dropChild()
        XCTAssert([Int](link) == [0])
    }

    func testParent() {
        let link = Link(0)
        link.addParent(Link(1))
        XCTAssert(link.parent?.value == 1)
        link.addParent(Link(2))
        XCTAssert(link.parent?.value == 2)
        XCTAssert([Int](link.tip()) == [2, 0])
        link.dropParent()
        XCTAssert([Int](link) == [0])
    }

    func testTipAndTail() {
        let link = Link(0)
        link.addParent(Link(-1))
        link.parent?.addParent(Link(-2))
        link.addChild(Link(1))
        link.child?.addChild(Link(2))

        XCTAssert(link.tip().value == -2)
        XCTAssert(link.tail().value == 2)
    }
}
