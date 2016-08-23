import Foundation
import XCTest
@testable import Leaf

class ParameterTests: XCTestCase {
    static let allTests = [
        ("testEquatable", testEquatable),
        ("testFromBytesThrows", testFromBytesThrows),
    ]

    func testEquatable() {
        var l = Parameter.variable(path: ["path", "to", "var"])
        var r = Parameter.variable(path: ["path", "to", "var"])
        XCTAssert(l == r)

        l = .constant(value: "constant-value")
        r = .constant(value: "constant-value")
        XCTAssert(l == r)

        l = .variable(path: ["simple", "path"])
        XCTAssert(l != r)
    }

    func testFromBytesThrows() throws {
        let bytes = Bytes()
        do {
            _ = try Parameter(bytes)
            XCTFail()
        } catch Parameter.Error.nonEmptyArgumentRequired {}
    }
}
