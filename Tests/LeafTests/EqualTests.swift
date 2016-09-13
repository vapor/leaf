import Foundation
import XCTest
@testable import Leaf

class EqualTests: XCTestCase {
    static let allTests = [
        ("testBasicEquals", testBasicEqual),
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

    func testComplexLoop() throws {
        let context = try Node(node: [
            "friends": [
                [
                    "name": "Venus",
                    "age": 12345
                ],
                [
                    "name": "Pluto",
                    "age": 888
                ],
                [
                    "name": "Mercury",
                    "age": 9000
                ]
            ]
            ])

        let template = try stem.spawnLeaf(named: "complex-loop")
        let loadable = Context(context)
        let rendered = try stem.render(template, with: loadable).string
        let expectation = "<li><b>Venus</b>: 12345</li>\n<li><b>Pluto</b>: 888</li>\n<li><b>Mercury</b>: 9000</li>\n"
        XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
    }

    func testNumberThrow() throws {
        let leaf = try stem.spawnLeaf(raw: "#loop(too, many, arguments)")
        let context = Context(["too": "", "many": "", "arguments": ""])
        do {
            _ = try stem.render(leaf, with: context).string
            XCTFail("Should throw")
        } catch Loop.Error.expectedTwoArguments { }
    }

    func testInvalidSignature1() throws {
        let leaf = try stem.spawnLeaf(raw: "#loop(\"invalid\", \"signature\")")
        let context = Context([:])
        do {
            _ = try stem.render(leaf, with: context).string
            XCTFail("Should throw")
        } catch Loop.Error.expectedVariable { }
    }

    func testInvalidSignature2() throws {
        let leaf = try stem.spawnLeaf(raw: "#loop(invalid, signature)")
        let context = Context([:])
        do {
            _ = try stem.render(leaf, with: context).string
            XCTFail("Should throw")
        } catch Loop.Error.expectedConstant { }
    }

    func testSkipNil() throws {
        let leaf = try stem.spawnLeaf(raw: "#loop(find-nil, \"inner-name\") { asdfasdfasdfsdf }")
        let context = Context([:])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "")
    }

    func testFuzzySingle() throws {
        // single => array
        let leaf = try stem.spawnLeaf(raw: "#loop(names, \"name\") { Hello, #(name)! }")
        let context = Context(["names": "Rick"])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "Hello, Rick!\n")
    }
}
