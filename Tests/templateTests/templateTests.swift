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
        var nameBuffer = Buffer("@someName(variable, \"argument\")".bytes)
        let name = try nameBuffer.extractInstructionName()
        XCTAssert(name == "someName")

        let arguments = try nameBuffer.extractArguments()
        XCTAssert(arguments == [.key("variable"), .value("argument")])
    }

    func testExtractBody() throws {
        var bodyBuffer = Buffer("{ hello, body! { sub body } }".bytes)
        let body = try bodyBuffer.extractBody()
        XCTAssert(body == "hello, body! { sub body }")
        print("")
    }

    func testExtractInstruction() throws {
        var instructionBuffer = Buffer("@instruction(variable, \"argument\") { here's a body @(sub-var) }".bytes)
        let instruction = try instructionBuffer.extractInstruction()
        XCTAssert(instruction.name == "instruction")
        XCTAssert(instruction.arguments == [.key("variable"), .value("argument")])
        XCTAssert(instruction.body == "here's a body @(sub-var)", "got body: \(instruction.body)")
    }

    func testComponents1() throws {
        let withCommand = "raw component followed by @command(self)"
        var withCommandBuffer = Buffer(withCommand.bytes)
        let comps = try withCommandBuffer.components()
        XCTAssert("\(comps[0])" == "raw(\"raw component followed by \")")
        XCTAssert("\(comps[1])" == "instruction(template.Instruction(name: \"command\", arguments: [template.InstructionArgument.key(\"self\")], body: \"@(self)\"))")
    }

    func testHelloTemplateComponents() throws {
        let helloData = NSData(contentsOfFile: workDir + "hello-test.vt")!
        var bytes = Bytes(repeating: 0, count: helloData.length)
        helloData.getBytes(&bytes, length: bytes.count)
        var template = Buffer(bytes)
        var comps = try template.components()
        print("Comps: \(comps)")
        print("")
    }
}
