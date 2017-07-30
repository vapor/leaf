import XCTest
@testable import Leaf
import Core

class LeafTests: XCTestCase {
    var renderer: Renderer!

    override func setUp() {
        self.renderer = Renderer.makeTestRenderer()
    }

    func testPrint() throws {
        let template = "Hello, #(name)!"
        let data = Data.dictionary(["name": .string("Tanner")])
        try XCTAssertEqual(renderer.render(template, context: data), "Hello, Tanner!")
    }

    func testConstant() throws {
        let template = "<h1>#(42)</h1>"
        try XCTAssertEqual(renderer.render(template, context: Data.empty), "<h1>42</h1>")
    }

    func testRecursive() throws {
        let template = """
        <p>#("foo: #(foo)")</p>
        """
        let data = Data.dictionary(["foo": .string("bar")])
        try XCTAssertEqual(renderer.render(template, context: data), "<p>foo: bar</p>")
    }

    func testExpression() throws {
        let template = "#(age > 99)"

        let young = Data.dictionary(["age": .int(21)])
        let old = Data.dictionary(["age": .int(150)])
        try XCTAssertEqual(renderer.render(template, context: young), "false")
        try XCTAssertEqual(renderer.render(template, context: old), "true")
    }

    func testBody() throws {
        let template = "#if(show){hi}"
        let noShow = Data.dictionary(["show": .bool(false)])
        let yesShow = Data.dictionary(["show": .bool(true)])
        try XCTAssertEqual(renderer.render(template, context: noShow), "")
        try XCTAssertEqual(renderer.render(template, context: yesShow), "hi")
    }

    func testRuntime() throws {
        let template = """
            #var("foo", "bar")
            Runtime: #(foo)"
        """
        try XCTAssert(renderer.render(template, context: Data.empty).contains("Runtime: bar"))
    }

    func testEmbed() throws {
        let template = """
            #embed("hello")
        """
        try XCTAssert(renderer.render(template, context: Data.empty).contains("hello.leaf"))
    }

    static var allTests = [
        ("testPrint", testPrint),
        ("testConstant", testConstant),
        ("testRecursive", testRecursive),
        ("testExpression", testExpression),
        ("testBody", testBody),
        ("testRuntime", testRuntime),
        ("testEmbed", testEmbed),
    ]
}
