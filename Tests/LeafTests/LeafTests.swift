import Foundation
import Async
import Dispatch
import Leaf
import Service
import XCTest

class LeafTests: XCTestCase {
    var renderer: LeafRenderer!
    var queue: Worker!

    override func setUp() {
        self.queue = try! DefaultEventLoop(label: "codes.vapor.leaf.test")
        let viewsDir = "/" + #file.split(separator: "/").dropLast(3).joined(separator: "/").finished(with: "/Views/")
        let config = LeafConfig(tags: defaultTags, viewsDir: viewsDir, shouldCache: false)
        self.renderer = LeafRenderer(config: config, on: queue)
    }

    func testRaw() throws {
        let template = "Hello!"
        try XCTAssertEqual(renderer.testRender(template), "Hello!")
    }

    func testPrint() throws {
        let template = "Hello, #(name)!"
        let data = TemplateData.dictionary(["name": .string("Tanner")])
        try XCTAssertEqual(renderer.testRender(template, data), "Hello, Tanner!")
    }

    func testConstant() throws {
        let template = "<h1>#(42)</h1>"
        try XCTAssertEqual(renderer.testRender(template), "<h1>42</h1>")
    }

    func testInterpolated() throws {
        let template = """
        <p>#("foo: #(foo)")</p>
        """
        let data = TemplateData.dictionary(["foo": .string("bar")])
        try XCTAssertEqual(renderer.testRender(template, data), "<p>foo: bar</p>")
    }

    func testNested() throws {
        let template = """
        <p>#(embed(foo))</p>
        """
        let data = TemplateData.dictionary(["foo": .string("bar")])
        try XCTAssertEqual(renderer.testRender(template, data), "<p>You have loaded bar.leaf!\n</p>")
    }

    func testExpression() throws {
        let template = "#(age > 99)"

        let young = TemplateData.dictionary(["age": .int(21)])
        let old = TemplateData.dictionary(["age": .int(150)])
        try XCTAssertEqual(renderer.testRender(template, young), "false")
        try XCTAssertEqual(renderer.testRender(template, old), "true")
    }

    func testBody() throws {
        let template = """
        #if(show) {hi}
        """
        let noShow = TemplateData.dictionary(["show": .bool(false)])
        let yesShow = TemplateData.dictionary(["show": .bool(true)])
        try XCTAssertEqual(renderer.testRender(template, noShow), "")
        try XCTAssertEqual(renderer.testRender(template, yesShow), "hi")
    }

    func testRuntime() throws {
        // FIXME: need to run var/exports first and in order
        let template = """
            #set("foo", "bar")
            Runtime: #(foo)
        """

        let res = try renderer.testRender(template)
        XCTAssert(res.contains("Runtime: bar"))
    }

    func testEmbed() throws {
        let template = """
        #embed("hello")
        """
        try XCTAssertEqual(renderer.testRender(template), "Hello, world!\n")
    }

//    func testError() throws {
//        do {
//            let template = "#if() { }"
//            _ = try renderer.testRender(template, .null)
//        } catch {
//            print("\(error)")
//        }
//
//        do {
//            let template = """
//            Fine
//            ##bad()
//            Good
//            """
//            _ = try renderer.testRender(template, .null)
//        } catch {
//            print("\(error)")
//        }
//
//        renderer.testRender("##()", .string"").do { data in
//            print(data)
//            // FIXME: check for error
//        }.catch { error in
//            print("\(error)")
//        }
//
//        do {
//            _ = try renderer.testRender("#if(1 == /)", .null)
//        } catch {
//            print("\(error)")
//        }
//    }

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

        let context = TemplateData.dictionary([
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
        try XCTAssertEqual(renderer.testRender(template, context), expect)
    }

    func testIfSugar() throws {
        let template = """
        #if(false) {Bad} else if (true) {Good} else {Bad}
        """
        try XCTAssertEqual(renderer.testRender(template, .null), "Good")
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
        try XCTAssertEqual(renderer.testRender(template, .null), "foobar")
        try XCTAssertEqual(renderer.testRender(multilineTemplate, .null), "foo\nbar")
    }

    func testHashtag() throws {
        let template = """
        #("hi") #thisIsNotATag...
        """
        try XCTAssertEqual(renderer.testRender(template, .null), "hi #thisIsNotATag...")
    }

    func testNot() throws {
        let template = """
        #if(!false) {Good} #if(!true) {Bad}
        """

        try XCTAssertEqual(renderer.testRender(template, .null), "Good")
    }

    func testFuture() throws {
        let template = """
        #if(false) {
            #(foo)
        }
        """

        var didAccess = false
        let context = TemplateData.dictionary([
            "foo": .lazy({
                didAccess = true
                return .string("hi")
            })
        ])
        try XCTAssertEqual(renderer.testRender(template, context), "")
        XCTAssertEqual(didAccess, false)
    }

    func testNestedBodies() throws {
        let template = """
        #if(true) {#if(true) {Hello\\}}}
        """
        try XCTAssertEqual(renderer.testRender(template, .null), "Hello}")
    }

    func testDotSyntax() throws {
        let template = """
        #if(user.isAdmin) {Hello, #(user.name)!}
        """

        let context = TemplateData.dictionary([
            "user": .dictionary([
                "isAdmin": .bool(true),
                "name": .string("Tanner")
            ])
        ])
        try XCTAssertEqual(renderer.testRender(template, context), "Hello, Tanner!")
    }

    func testEqual() throws {
        let template = """
        #if(user.id == 42) {User 42!} #if(user.id != 42) {Shouldn't show up}
        """

        let context = TemplateData.dictionary([
            "user": .dictionary([
                "id": .int(42),
                "name": .string("Tanner")
            ])
        ])
        try XCTAssertEqual(renderer.testRender(template, context), "User 42!")
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
        try XCTAssertEqual(renderer.testRender(template, .null), expected)
    }


    func testEscapeTag() throws {
        let template = """
        #("foo") \\#("bar")
        """
        let expected = """
        foo #("bar")
        """
        try XCTAssertEqual(renderer.testRender(template, .null), expected)
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

        let context = TemplateData.dictionary([
            "items": .array([.string("foo"), .string("bar"), .string("baz")])
        ])
        try XCTAssertEqual(renderer.testRender(template, context), expected)
    }

//    func testAsyncExport() throws {
//        let preloaded = PreloadedFiles()
//
//        preloaded.files["/template.leaf"] = """
//        Content: #get(content)
//        """.data(using: .utf8)!
//
//        preloaded.files["/nested.leaf"] = """
//        Nested!
//        """.data(using: .utf8)!
//
//        let template = """
//        #set("content") {<p>#embed("nested")</p>}
//        #embed("template")
//        """
//
//        let expected = """
//        Content: <p>Nested!</p>
//        """
//
//        let config = LeafConfig { _ in
//            return preloaded
//        }
//        let renderer = LeafRenderer(config: config, on: queue)
//        try XCTAssertEqual(renderer.testRender(template, .null).blockingAwait(), expected)
//    }

    func testReactiveStreams() throws {
        let template = "#for(int in integers) {#(int),}"
        
        let expected = """
        1,2,3,4,5,6,7,8,9,9,8,7,6,5,4,3,2,1,
        """
        
        let emitter = EmitterStream<Int>()
        
        let data = TemplateData.dictionary([
            "integers": TemplateData.convert(stream: emitter)
        ])
        let render = renderer.render(template: template.data(using: .utf8)!, data)
        
        for i in 1..<10 {
            emitter.emit(i)
        }
        
        for i in (1..<10).reversed() {
            emitter.emit(i)
        }
        
        emitter.close()
        
        let rendered = try render.map(to: String.self) { String(data: $0.data, encoding: .utf8)! }
            .blockingAwait()
        XCTAssertEqual(rendered, expected)
    }

//    func testService() throws {
//        var services = Services()
//        try services.register(LeafProvider())
//
//        services.register { container in
//            return LeafConfig(tags: defaultTags, viewsDir: "/") { queue in
//                TestFiles()
//            }
//        }
//
//        let container = BasicContainer(config: Config(), environment: .development, services: services, on: queue)
//        let view = try container.make(TemplateRenderer.self, for: XCTest.self)
//
//        struct TestContext: Encodable {
//            var name = "test"
//        }
//        let rendered = view.testRender("foo", TestContext())
//        let expected = """
//        Test file name: "/foo.leaf"
//        """
//
//        XCTAssertEqual(String(data: rendered.data, encoding: .utf8), expected)
//    }

    func testCount() throws {
        let template = """
        count: #count(array)
        """
        let expected = """
        count: 4
        """
        let context = TemplateData.dictionary(["array": .array([.null, .null, .null, .null])])
        try XCTAssertEqual(renderer.testRender(template, context), expected)
    }

    func testNestedSet() throws {
        let template = """
        #if(a) {
            #set("title") {A}
        }
        title: #get(title)
        """
        let expected = """

        title: A
        """

        let context = TemplateData.dictionary(["a": .bool(true)])
        try XCTAssertEqual(renderer.testRender(template, context), expected)
    }

    func testDateFormat() throws {
        let template = """
        Date: #date(foo, "yyyy-MM-dd")
        """

        let expected = """
        Date: 2001-01-16
        """

        let context = TemplateData.dictionary(["foo": .double(1_337_000)])
        try XCTAssertEqual(renderer.testRender(template, context), expected)

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
//        ("testAsyncExport", testAsyncExport),
//        ("testService", testService),
        ("testCount", testCount),
        ("testNestedSet", testNestedSet),
    ]
}

extension TemplateRenderer {
    func testRender(_ template: String, _ context: TemplateData = .null) throws -> String {
        let view = try self.render(template: template.data(using: .utf8)!, context).blockingAwait(timeout: .seconds(5))
        return String(data: view.data, encoding: .utf8)!
    }
}
