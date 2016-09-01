import Foundation
import XCTest
@testable import Leaf

class PerformanceTests: XCTestCase {
    static let allTests = [
        ("testLeaf", testLeaf),
        ("testContextGet", testContextGet),
        ("testContextPush", testContextPush),
        ("testLeafLong", testLeafLong),
    ]

    func testLeaf() throws {
        let raw = "Hello, *(name)!"
        let expectation = "Hello, World!".bytes
        let template = try stem.spawnLeaf(raw: raw)
        let ctxt = Context(["name": "World"])
        measure {
            try! (1...500).forEach { _ in
                let rendered = try stem.render(template, with: ctxt)
                XCTAssert(rendered == expectation)
            }
        }
    }

    func testContextGet() throws {
        let ctxt = Context(["name": "World"])
        measure {
            (1...500).forEach { _ in
                _ = ctxt.get(path: ["name"])
            }
        }
    }

    func testContextPush() throws {
        let ctxt = Context(["name": "World"])
        measure {
            (1...500).forEach { _ in
                _ = ctxt.push(["self": "..."])
                defer { ctxt.pop() }
            }
        }
    }

    func testLeafLong() throws {
        let raw = [String](repeating: "Hello, *(name)!", count: 1000).joined(separator: ", ")
        let expectation = [String](repeating: "Hello, World!", count: 1000).joined(separator: ", ").bytes
        let template = try stem.spawnLeaf(raw: raw)
        _ = template.description
        let ctxt = Context(["name": "World"])
        measure {
            try! (1...5).forEach { _ in
                let rendered = try stem.render(template, with: ctxt)
                XCTAssert(rendered == expectation)
            }
        }
    }
}
