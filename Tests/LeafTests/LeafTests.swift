import XCTest
@testable import Leaf

class LeafTests: XCTestCase {
    var renderer: Renderer!

    override func setUp() {
        self.renderer = Renderer.makeTestRenderer()
    }

    func testRaw() throws {
        let template = "Hello!"
        try XCTAssertEqual(renderer.render(template, context: Context.null).await(), "Hello!")
    }

    func testPrint() throws {
        let template = "Hello, #(name)!"
        let data = Context.dictionary(["name": .string("Tanner")])
        try XCTAssertEqual(renderer.render(template, context: data).await(), "Hello, Tanner!")
    }

    func testConstant() throws {
        let template = "<h1>#(42)</h1>"
        try XCTAssertEqual(renderer.render(template, context: Context.null).await(), "<h1>42</h1>")
    }

    func testInterpolated() throws {
        let template = """
        <p>#("foo: #(foo)")</p>
        """
        let data = Context.dictionary(["foo": .string("bar")])
        try XCTAssertEqual(renderer.render(template, context: data).await(), "<p>foo: bar</p>")
    }

    func testNested() throws {
        let template = """
        <p>#(embed(foo))</p>
        """
        let data = Context.dictionary(["foo": .string("bar")])
        try XCTAssertEqual(renderer.render(template, context: data).await(), "<p>Test file name: &quot;bar.leaf&quot;</p>")
    }

    func testExpression() throws {
        let template = "#(age > 99)"

        let young = Context.dictionary(["age": .int(21)])
        let old = Context.dictionary(["age": .int(150)])
        try XCTAssertEqual(renderer.render(template, context: young).await(), "false")
        try XCTAssertEqual(renderer.render(template, context: old).await(), "true")
    }

    func testBody() throws {
        let template = """
        #if(show) {hi}
        """
        let noShow = Context.dictionary(["show": .bool(false)])
        let yesShow = Context.dictionary(["show": .bool(true)])
        try XCTAssertEqual(renderer.render(template, context: noShow).await(), "")
        try XCTAssertEqual(renderer.render(template, context: yesShow).await(), "hi")
    }

    func testRuntime() throws {
        let template = """
            #var("foo", "bar")
            Runtime: #(foo)
        """
        let res = try renderer.render(template, context: Context.dictionary([:])).await()
        XCTAssert(res.contains("Runtime: bar"))
    }

    func testEmbed() throws {
        let template = """
            #embed("hello")
        """
        try XCTAssert(renderer.render(template, context: Context.null).await().contains("hello.leaf"))
    }

    func testError() throws {
        do {
            let template = "#if() { }"
            _ = try renderer.render(template, context: Context.null).await()
        } catch {
            print("\(error)")
        }

        do {
            let template = """
            Fine
            ##bad()
            Good
            """
            _ = try renderer.render(template, context: Context.null).await()
        } catch {
            print("\(error)")
        }

        renderer.render(path: "##()", context: Context.null).then { data in
            print(data)
            // FIXME: check for error
        }

        do {
            _ = try renderer.render("#if(1 == /)", context: Context.null).await()
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
        try XCTAssertEqual(renderer.render(template, context: Context.null).await(), "It works!")
    }

    func testForSugar() throws {
        let template = """
        <p>
            <ul>
                #for(name in names) {
                    <li>#(name)</li>
                }
            </ul>
        </p>
        """

        let context = Context.dictionary([
            "names": .array([
                .string("Vapor"), .string("Leaf"), .string("Bits")
            ])
        ])

        let expect = """
        <p>
            <ul>
                <li>Vapor</li>
                <li>Leaf</li>
                <li>Bits</li>
            </ul>
        </p>
        """
        try XCTAssertEqual(renderer.render(template, context: context).await(), expect)
    }

    func testIfSugar() throws {
        let template = """
        #if(false) {Bad} else if (true) {Good} else {Bad}
        """
        try XCTAssertEqual(renderer.render(template, context: Context.null).await(), "Good")
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
        try XCTAssertEqual(renderer.render(template, context: Context.null).await(), "foobar")
        try XCTAssertEqual(renderer.render(multilineTemplate, context: Context.null).await(), "foo\nbar")
    }

    func testHashtag() throws {
        let template = """
        #("hi") #thisIsNotATag...
        """
        try XCTAssertEqual(renderer.render(template, context: Context.null).await(), "hi #thisIsNotATag...")
    }

    func testNot() throws {
        let template = """
        #if(!false) {Good} #if(!true) {Bad}
        """

        try XCTAssertEqual(renderer.render(template, context: Context.null).await(), "Good")
    }

    func testFuture() throws {
        let template = """
        #if(false) {
            #(foo)
        }
        """

        var didAccess = false
        let context = Context.dictionary([
            "foo": .lazy({
                didAccess = true
                return .string("hi")
            })
        ])

        try XCTAssertEqual(renderer.render(template, context: context).await(), "")
        XCTAssertEqual(didAccess, false)
    }

    func testNestedBodies() throws {
        let template = """
        #if(true) {#if(true) {Hello\\}}}
        """
        try XCTAssertEqual(renderer.render(template, context: Context.null).await(), "Hello}")
    }

    func testDotSyntax() throws {
        let template = """
        #if(user.isAdmin) {Hello, #(user.name)!}
        """

        let context = Context.dictionary([
            "user": .dictionary([
                "isAdmin": .bool(true),
                "name": .string("Tanner")
            ])
        ])
        try XCTAssertEqual(renderer.render(template, context: context).await(), "Hello, Tanner!")
    }

    func testEqual() throws {
        let template = """
        #if(user.id == 42) {User 42!} #if(user.id != 42) {Shouldn't show up}
        """

        let context = Context.dictionary([
            "user": .dictionary([
                "id": .int(42),
                "name": .string("Tanner")
            ])
        ])
        try XCTAssertEqual(renderer.render(template, context: context).await(), "User 42!")
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
        try XCTAssertEqual(renderer.render(template, context: Context.null).await(), expected)
    }


    func testEscapeTag() throws {
        let template = """
        #("foo") \\#("bar")
        """
        let expected = """
        foo #("bar")
        """
        try XCTAssertEqual(renderer.render(template, context: Context.null).await(), expected)
    }

    func testIndentationCorrection() throws {
        let template = """
        <p>
            <ul>
                #for(item in items) {
                    #if(true) {
                        <li>#(item)</li>
                        <br>
                    }
                }
            </ul>
        </p>
        """

        let expected = """
        <p>
            <ul>
                <li>foo</li>
                <br>
                <li>bar</li>
                <br>
                <li>baz</li>
                <br>
            </ul>
        </p>
        """

        let context: Context = .dictionary([
            "items": .array([.string("foo"), .string("bar"), .string("baz")])
        ])

        try XCTAssertEqual(renderer.render(template, context: context).await(), expected)
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
        ("testEscapeTag", testEscapeTag),
        ("testIndentationCorrection", testIndentationCorrection),
    ]
}
