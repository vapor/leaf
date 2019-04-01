import Foundation
import Async
import Dispatch
import Leaf
import Service
import XCTest

class LeafTests: XCTestCase {
    var renderer: LeafRenderer!

    override func setUp() {
        let container = BasicContainer(config: .init(), environment: .testing, services: .init(), on: EmbeddedEventLoop())
        let viewsDir = "/" + #file.split(separator: "/").dropLast(3).joined(separator: "/").finished(with: "/Views/")
        let config = LeafConfig(tags: .default(), viewsDir: viewsDir, shouldCache: false)
        self.renderer = LeafRenderer(config: config, using: container)
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

    func testForSugar() throws {
        let template = """
        <p>
            <ul>
                #for(name in names) {<li>#(name)</li>}
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
                <li>Vapor</li><li>Leaf</li><li>Bits</li>
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
        try XCTAssertEqual(renderer.testRender(template, .null), "foo\nbar")
        try XCTAssertEqual(renderer.testRender(multilineTemplate, .null), "foo\n\nbar")
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
        #if(a){#set("title"){A}}title: #get(title)
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
        Date: 1970-01-16
        """

        let context = TemplateData.dictionary(["foo": .double(1_337_000)])
        try XCTAssertEqual(renderer.testRender(template, context), expected)

    }

    func testStringIf() throws {
        let template = "#if(name){Hello, #(name)!}"
        let expected = "Hello, Tanner!"
        let context = TemplateData.dictionary(["name": .string("Tanner")])
        try XCTAssertEqual(renderer.testRender(template, context), expected)
    }

    func testEmptyForLoop() throws {
        let template = """
        #for(category in categories) {
            <a class=“dropdown-item” href=“#”>#(category.name)</a>
        }
        """
        let expected = """
        """

        struct Category: Encodable {
            var name: String
        }

        struct Context: Encodable {
            var categories: [Category]
        }

        let context = Context(categories: [])
        let data = try TemplateDataEncoder().testEncode(context)
        try XCTAssertEqual(renderer.testRender(template, data), expected)

    }

    func testKeyEqual() throws {
        let template = """
        #if(title == "foo") {it's foo} else {not foo}
        """
        let expected = """
        it's foo
        """

        struct Stuff: Encodable {
            var title: String
        }

        let context = Stuff(title: "foo")
        let data = try TemplateDataEncoder().testEncode(context)
        try XCTAssertEqual(renderer.testRender(template, data), expected)
    }

    func testInvalidForSyntax() throws {
        let data = try TemplateDataEncoder().testEncode(["names": ["foo"]])
        do {
            _ = try renderer.testRender("#for( name in names) {}", data)
            XCTFail("Whitespace not allowed here")
        } catch {
            XCTAssert("\(error)".contains("space not allowed"))
        }

        do {
            _ = try renderer.testRender("#for(name in names ) {}", data)
            XCTFail("Whitespace not allowed here")
        } catch {
            XCTAssert("\(error)".contains("space not allowed"))
        }

        do {
            _ = try renderer.testRender("#for( name in names ) {}", data)
            XCTFail("Whitespace not allowed here")
        } catch {
            XCTAssert("\(error)".contains("space not allowed"))
        }

        do {
            _ = try renderer.testRender("#for(name in names) {}", data)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testTemplating() throws {
        let home = """
        #set("title", "Home")#set("body"){<p>#(foo)</p>}#embed("base")
        """
        let expected = """
        <title>Home</title>
        <body><p>bar</p></body>
        
        """
        renderer.astCache = ASTCache()
        defer { renderer.astCache = nil }
        let data = try TemplateDataEncoder().testEncode(["foo": "bar"])
        try XCTAssertEqual(renderer.testRender(home, data), expected)
        try XCTAssertEqual(renderer.testRender(home, data), expected)
    }

    // https://github.com/vapor/leaf/issues/96
    func testGH96() throws {
        let template = """
        #for(name in names) {
            #(name): index=#(index) last=#(isLast) first=#(isFirst)
        }
        """
        let expected = """

            tanner: index=0 last=false first=true

            ziz: index=1 last=false first=false

            vapor: index=2 last=true first=false

        """
        let data = try TemplateDataEncoder().testEncode([
            "names": ["tanner", "ziz", "vapor"]
        ])
        try XCTAssertEqual(renderer.testRender(template, data), expected)
    }
    
    // https://github.com/vapor/leaf/issues/99
    func testGH99() throws {
        let template = """
        Hi #(first) #(last)
        """
        let expected = """
        Hi Foo Bar
        """
        let data = try TemplateDataEncoder().testEncode([
            "first": "Foo", "last": "Bar"
        ])
        try XCTAssertEqual(renderer.testRender(template, data), expected)
    }
    
    // https://github.com/vapor/leaf/issues/101
    func testGH101() throws {
        let template = """
        #for(foo in foos){#(index+1):#(foo)}
        """
        let expected = "1:A2:B3:C"
        let data = try TemplateDataEncoder().testEncode([
            "foos": ["A", "B", "C"]
        ])
        try XCTAssertEqual(renderer.testRender(template, data), expected)
    }
    
    // https://github.com/vapor/leaf/issues/105
    func testGH105() throws {
        do {
            let template = """
            #if(1 + 1 == 2) {hi}
            """
            let expected = "hi"
            let data = try TemplateDataEncoder().testEncode(["a": "a"])
            try XCTAssertEqual(renderer.testRender(template, data), expected)
        }
        do {
            let template = """
            #if(2 == 1 + 1) {hi}
            """
            let expected = "hi"
            let data = try TemplateDataEncoder().testEncode(["a": "a"])
            try XCTAssertEqual(renderer.testRender(template, data), expected)
        }
        do {
            let template = """
            #if(1 == 1 + 1 || 1 == 2 - 1) {hi}
            """
            let expected = "hi"
            let data = try TemplateDataEncoder().testEncode(["a": "a"])
            try XCTAssertEqual(renderer.testRender(template, data), expected)
        }
    }

    // https://github.com/vapor/leaf/issues/127
    func testGH127Inline() throws {
        do {
            let template = """
            <html>
            <head>
            <title></title>#// Translate all copy!!!!!
            <style>
            """
            let expected = """
            <html>
            <head>
            <title></title>
            <style>
            """
            let data = try TemplateDataEncoder().testEncode(["a": "a"])
            try XCTAssertEqual(renderer.testRender(template, data), expected)
        }
    }

    func testGH127SingleLine() throws {
        do {
            let template = """
            <html>
            <head>
            <title></title>
            #// Translate all copy!!!!!
            <style>
            """
            let expected = """
            <html>
            <head>
            <title></title>
            <style>
            """
            let data = try TemplateDataEncoder().testEncode(["a": "a"])
            try XCTAssertEqual(renderer.testRender(template, data), expected)
        }
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
        ("testCount", testCount),
        ("testNestedSet", testNestedSet),
        ("testDateFormat", testDateFormat),
        ("testStringIf", testStringIf),
        ("testEmptyForLoop", testEmptyForLoop),
        ("testKeyEqual", testKeyEqual),
        ("testInvalidForSyntax", testInvalidForSyntax),
        ("testTemplating", testTemplating),
        ("testGH96", testGH96),
        ("testGH99", testGH99),
        ("testGH101", testGH101),
        ("testGH105", testGH105),
        ("testGH127Inline", testGH127Inline),
        ("testGH127SingleLine", testGH127SingleLine),
        ("testRenderPerformance", testRenderPerformance)
    ]
}

// MARK: - Performance

extension LeafTests {
    private struct ExampleModel: Encodable {
        var id: Int = 1

        var string1: String = "a"
        var string2: String = String(repeating: "b", count: 5)
        var string3: String = String(repeating: "abcdef", count: 2)
        var string4: String? = String(repeating: "abc1", count: 4)
        var string5: String? = String(repeating: "xyz2", count: 4)
        var string6: String? = String(repeating: "100letters", count: 10)

        var emptyString1: String? = nil
        var emptyString2: String? = nil
        var emptyString3: String? = nil

        var int1: Int = 1
        var int2: Int = 2
        var int3: Int? = nil
        var int4: UInt8 = 1
        var int5: UInt8 = 2
        var int6: UInt8? = nil

        var date1: Date = Date(timeIntervalSince1970: 1546300800)  // Midnight (GMT) April 1st, 2019
        var date2: Date? = Date(timeIntervalSince1970: 1546300800)  // Midnight (GMT) April 1st, 2019
        var date3: Date? = Date(timeIntervalSince1970: 1546300800)  // Midnight (GMT) April 1st, 2019
        var date4: Date? = Date(timeIntervalSince1970: 1546300800)  // Midnight (GMT) April 1st, 2019
        var date5: Date? = nil

        var double1: Double = 1
        var double2: Double? = 2
        var double3: Double? = nil

        var uuid: UUID = UUID()
    }

    private struct Index: Encodable {
        var models = Array(repeating: ExampleModel(), count: 500)
    }

    private static let exampleIndex = Index()

    func testRenderPerformance() throws {
        let context = try! TemplateDataEncoder().testEncode(Index())
        let template = """
#for(row in models) {
<tr>
<td>#(row.id)</td>
<td>#(row.string1)</td>
<td>#(row.string2)</td>
<td>#(row.string3)</td>
<td>#(row.string4)</td>
<td>#(row.string5)</td>
<td>#(row.string6)</td>
<td>#(row.emptyString1)</td>
<td>#(row.emptyString2)</td>
<td>#(row.emptyString3)</td>
<td>#(row.int1)</td>
<td>#(row.int2)</td>
<td>#(row.int3)</td>
<td>#(row.int4)</td>
<td>#(row.int5)</td>
<td>#(row.int6)</td>
<td>#(date(row.date1, "yyyy-MM-dd HH:mm:ss"))</td>
<td>#(date(row.date2, "yyyy-MM-dd HH:mm:ss"))</td>
<td>#(date(row.date3, "yyyy-MM-dd"))</td>
<td>#(date(row.date4, "HH:mm:ss"))</td>
<td>#(date(row.date5, "yyyy-MM-dd HH:mm:ss"))</td>
<td>#(row.double1)</td>
<td>#(row.double2)</td>
<td>#(row.double3)</td>
<td>#(row.uuid)</td>
</tr>
}
"""
        measure {
            _ = try! renderer.testRender(template, context)
        }
    }
}

extension TemplateRenderer {
    func testRender(_ template: String, _ context: TemplateData = .null) throws -> String {
        let view = try self.render(template: template.data(using: .utf8)!, context).wait()
        return String(data: view.data, encoding: .utf8)!
    }
}
