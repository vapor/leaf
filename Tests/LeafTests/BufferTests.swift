import Foundation
import XCTest
@testable import Leaf

class BufferTests: XCTestCase {
    static let allTests = [
        ("testSectionOpenerThrow", testSectionOpenerThrow),
        ("testSectionCloserThrow", testSectionCloserThrow),
    ]

    func testSectionOpenerThrow() throws {
        var buffer = Buffer("No opener".makeBytes())
        do {
            _ = try buffer.extractSection(opensWith: .period, closesWith: .period)
            XCTFail()
        } catch ParseError.missingBodyOpener {}
    }

    func testSectionCloserThrow() throws {
        var buffer = Buffer(". No closer".makeBytes())
        do {
            _ = try buffer.extractSection(opensWith: .period, closesWith: .period)
            XCTFail()
        } catch ParseError.missingBodyCloser {}
    }
}
