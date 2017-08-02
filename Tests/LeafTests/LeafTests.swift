import XCTest
@testable import Leaf

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

    func testInterpolated() throws {
        let template = """
        <p>#("foo: #(foo)")</p>
        """
        let data = Data.dictionary(["foo": .string("bar")])
        try XCTAssertEqual(renderer.render(template, context: data), "<p>foo: bar</p>")
    }

    func testNested() throws {
        let template = """
        <p>#(embed(foo))</p>
        """
        let data = Data.dictionary(["foo": .string("bar")])
        try XCTAssertEqual(renderer.render(template, context: data), "<p>Test file name: &quot;bar.leaf&quot;</p>")
    }

    func testExpression() throws {
        let template = "#(age > 99)"

        let young = Data.dictionary(["age": .int(21)])
        let old = Data.dictionary(["age": .int(150)])
        try XCTAssertEqual(renderer.render(template, context: young), "false")
        try XCTAssertEqual(renderer.render(template, context: old), "true")
    }

    func testBody() throws {
        let template = """
        #if(show) {hi}
        """
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

    func testError() throws {
        do {
            let template = "#if() { }"
            _ = try renderer.render(template, context: Data.empty)
        } catch {
            print("\(error)")
        }

        do {
            let template = """
            Fine
            ##bad()
            Good
            """
            _ = try renderer.render(template, context: Data.empty)
        } catch {
            print("\(error)")
        }

        do {
            _ = try renderer.render(path: "##()", context: Data.empty)
        } catch {
            print("\(error)")
        }
    }

    func testChained() throws {
        let template = """
        #ifElse(false) {

        } ##ifElse(false) {

        } ##ifElse(true) {It works!}
        """
        try XCTAssertEqual(renderer.render(template, context: Data.empty), "It works!")
    }

    func testForSugar() throws {
        let template = """
        <p>
            <ul>
                #for(name in names) {<li>#(name)</li>}
            </ul>
        </p>
        """

        let context = Data.dictionary([
            "names": .array([
                .string("Vapor"), .string("Leaf"), .string("Bits")
            ])
        ])

        let expect = """
        <p>
            <ul>
                <li>Vapor</li><li>Leaf</li><li>Bits</li>
            </ul>
        </p>
        """
        try XCTAssertEqual(renderer.render(template, context: context), expect)
    }

    func testIfSugar() throws {
        let template = """
        #if(false) {Bad} else if (true) {Good} else {Bad}
        """
        try XCTAssertEqual(renderer.render(template, context: Data.empty), "Good")
    }

    func testCommentSugar() throws {
        let template = """
        #("foo")
        #// this is a comment!
        bar
        """

        let multilineTemplate = """
        #("foo")
        #/*
            this is a comment!
        */
        bar
        """
        try XCTAssertEqual(renderer.render(template, context: Data.empty), "foo\nbar")
        try XCTAssertEqual(renderer.render(multilineTemplate, context: Data.empty), "foo\n\nbar")
    }

    func testHashtag() throws {
        let template = """
        #("hi") #thisIsNotATag...
        """
        try XCTAssertEqual(renderer.render(template, context: Data.empty), "hi #thisIsNotATag...")
    }

    func testNot() throws {
        let template = """
        #if(!false) {Good} #if(!true) {Bad}
        """

        try XCTAssertEqual(renderer.render(template, context: Data.empty), "Good")
    }

    func testFuture() throws {
        let template = """
        #if(false) {
            #(foo)
        }
        """

        var didAccess = false
        let context = Data.dictionary([
            "foo": .future({
                didAccess = true
                return .string("hi")
            })
        ])

        try XCTAssertEqual(renderer.render(template, context: context), "")
        XCTAssertEqual(didAccess, false)
    }

    func testNestedBodies() throws {
        let template = """
        #if(true) {#if(true) {Hello\\}}}
        """
        try XCTAssertEqual(renderer.render(template, context: Data.empty), "Hello}")
    }

    func testDotSyntax() throws {
        let template = """
        #if(user.isAdmin) {Hello, #(user.name)!}
        """

        let context = Data.dictionary([
            "user": .dictionary([
                "isAdmin": .bool(true),
                "name": .string("Tanner")
            ])
        ])
        try XCTAssertEqual(renderer.render(template, context: context), "Hello, Tanner!")
    }

    func testEqual() throws {
        let template = """
        #if(user.id == 42) {User 42!} #if(user.id != 42) {
            Shouldn't show up
        }
        """

        let context = Data.dictionary([
            "user": .dictionary([
                "id": .int(42),
                "name": .string("Tanner")
            ])
        ])
        try XCTAssertEqual(renderer.render(template, context: context), "User 42!")
    }

    func testEscapeExtraneousBody() throws {
        let template = """
        extension #("User") \\{

        }
        """
        let expected = """
        extension User {

        }
        """
        try XCTAssertEqual(renderer.render(template, context: Data.empty), expected)
    }

    static var allTests = [
        ("testPrint", testPrint),
        ("testConstant", testConstant),
        ("testInterpolated", testInterpolated),
        ("testNested", testNested),
        ("testExpression", testExpression),
        ("testBody", testBody),
        ("testRuntime", testRuntime),
        ("testEmbed", testEmbed),
        ("testChained", testChained),
        ("testIfSugar", testIfSugar),
        ("testCommentSugar", testCommentSugar),
        ("testHashtag", testHashtag),
        ("testNot", testNot),
        ("testFuture", testFuture),
        ("testNestedBodies", testNestedBodies),
        ("testDotSyntax", testDotSyntax),
        ("testEqual", testEqual),
        ("testEscapeExtraneousBody", testEscapeExtraneousBody),
    ]
}
