import Foundation
import XCTest
@testable import Leaf

class EqualTests: XCTestCase {
    static let allTests = [
        ("testBasicEquals", testBasicEqual),
        ("testFuzzy", testFuzzy),
        ("testEmpty", testEmpty),
        ("testArraysFuzzy", testArraysFuzzy),
        ("testArraysNotEqual", testArraysNotEqual),
        ("testArraysBadType", testArraysBadType),
        ("testBytes", testBytes),
        ("testBytesBadType", testBytesBadType),
        ("testNumberDouble", testNumberDouble),
        ("testNumberInt", testNumberInt),
        ("testNumberUInt", testNumberUInt),
        ("testObject", testObject),
        ("testObjectNotEqual", testObjectNotEqual),
        ("testObjectNotEqualCount", testObjectNotEqualCount),
        ("testObjectBadType", testObjectBadType),
        ("testBadSignature", testBadSignature),
    ]

    func testBasicEqual() throws {
        let template = try stem.spawnLeaf(raw: "#equal(name, \"Hello\") { yes } ##else() { no }")
        let cases: [(input: String, expectation: String)] = [
            ("Hello", "yes"),
            ("sadf", "no")
        ]
        try cases.forEach { input, expectation in
            let rendered = try stem.render(template, with: try Context(Node(node: ["name": input]))).string
            XCTAssertEqual(rendered, expectation)
        }
    }

    func testFuzzy() throws {
        let template = try stem.spawnLeaf(raw: "#equal(bool, \"true\") { yes }")
        let rendered = try stem.render(template, with: Context(["bool": true])).string
        let expectation = "yes"
        XCTAssertEqual(rendered, expectation)
    }

    func testEmpty() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes }")
        let rendered = try stem.render(template, with: Context([:])).string
        let expectation = "yes"
        XCTAssertEqual(rendered, expectation)
    }

    func testArraysFuzzy() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes }")
        let node = try Node(node:
            [
                "a": [1,2,3],
                "b": ["1", "2", "3"]
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "yes"
        XCTAssertEqual(rendered, expectation)
    }

    func testArraysNotEqual() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes } ##else() { no }")
        let node = try Node(node:
            [
                "a": [1,2,3],
                "b": ["1", "2", "3", "4"]
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "no"
        XCTAssertEqual(rendered, expectation)
    }

    func testArraysBadType() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes } ##else() { no }")
        let node = try Node(node:
            [
                "a": [1,2,3],
                "b": "I'm not an array"
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "no"
        XCTAssertEqual(rendered, expectation)
    }

    func testBytes() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes } ##else() { no }")
        let node = try Node(node:
            [
                "a": .bytes([1,2,3]),
                "b": .bytes([1,2,3])
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "yes"
        XCTAssertEqual(rendered, expectation)
    }

    func testBytesBadType() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes } ##else() { no }")
        let node = try Node(node:
            [
                "a": .bytes([1,2,3]),
                "b": "I'm not bytes"
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "no"
        XCTAssertEqual(rendered, expectation)
    }

    func testNumberDouble() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes } ##else() { no }")
        let node = try Node(node:
            [
                "a": 3.14,
                "b": "3.14"
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "yes"
        XCTAssertEqual(rendered, expectation)
    }

    func testNumberInt() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes } ##else() { no }")
        let node = try Node(node:
            [
                "a": 42,
                "b": 42.0
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "yes"
        XCTAssertEqual(rendered, expectation)
    }

    func testNumberUInt() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes } ##else() { no }")
        let node = try Node(node:
            [
                "a": UInt(4255),
                "b": "4255"
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "yes"
        XCTAssertEqual(rendered, expectation)
    }

    func testObject() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes } ##else() { no }")
        let node = try Node(node:
            [
                "a": ["name": "same"],
                "b": ["name": "same"]
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "yes"
        XCTAssertEqual(rendered, expectation)
    }

    func testObjectNotEqual() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes } ##else() { no }")
        let node = try Node(node:
            [
                "a": ["name": "not"],
                "b": ["name": "same"]
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "no"
        XCTAssertEqual(rendered, expectation)
    }

    func testObjectNotEqualCount() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes } ##else() { no }")
        let node = try Node(node:
            [
                "a": ["name": "same", "more": "foo"],
                "b": ["name": "same"]
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "no"
        XCTAssertEqual(rendered, expectation)
    }

    func testObjectBadType() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b) { yes } ##else() { no }")
        let node = try Node(node:
            [
                "a": ["name": "a"],
                "b": "I'm no object"
            ]
        )
        let rendered = try stem.render(template, with: Context(node)).string
        let expectation = "no"
        XCTAssertEqual(rendered, expectation)
    }

    func testBadSignature() throws {
        let template = try stem.spawnLeaf(raw: "#equal(a, b, c)")
        do {
            _ = try stem.render(template, with: Context([:])).string
            XCTFail("Should throw")
        } catch Equal.Error.expected2Arguments {}
    }
}
