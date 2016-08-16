import Core
import Foundation
import XCTest
@testable import template

var workDir: String {
    let parent = #file.characters.split(separator: "/").map(String.init).dropLast().joined(separator: "/")
    let path = "/\(parent)/../../Resources/"
    return path
}

class templateTests: XCTestCase {
    static let allTests = [
        ("testExample", testExample),
    ]

    func testExample() {

        let helloData = NSData(contentsOfFile: workDir + "hello-test.vt")!
        var bytes = Bytes(repeating: 0, count: helloData.length)
        helloData.getBytes(&bytes, length: bytes.count)
        let template = Template(raw: bytes.string)
        print("GOT: \(template)")
        print("")
    }

    func testExtractName() throws {
        let nameBuffer = Buffer("@someName(variable, \"argument\")".bytes)
        let name = try nameBuffer.extractInstructionName()
        XCTAssert(name.string == "someName")

        let arguments = try nameBuffer.extractArguments()
        XCTAssert(arguments.string == "variable, \"argument\"")
    }

    func testExtractBody() throws {
        let bodyBuffer = Buffer("{ hello, body! { sub body } }".bytes)
        let body = try bodyBuffer.extractBody()
        XCTAssert(body.string == "hello, body! { sub body }")
        print("")
    }
}
