import Foundation
import XCTest
@testable import Leaf

class RenderTests: XCTestCase {
    static let allTests = [
        ("testCustomStemComponents", testCustomStemComponents),
        ("testBasicRender", testBasicRender),
        ("testNestedBodyRender", testNestedBodyRender),
        ("testSpawnThrow", testSpawnThrow),
        ("testRenderThrowMissingTag", testRenderThrowMissingTag),
        ("testRenderNil", testRenderNil),
    ]

    func testCustomStemComponents() throws {
        let temporaryTag = Test(name: "test", value: "Passed", shouldRender: true)
        stem.register(temporaryTag)
        defer { stem.remove(temporaryTag) }

        let leaf = try stem.spawnLeaf(raw: "Custom ^test()")
        let context = Context([:])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "Custom Passed")
    }

    func testBasicRender() throws {
        let template = try stem.spawnLeaf(named: "basic-render")
        let contexts = ["a", "ab9^^^", "ajcm301kc,s--11111", "World", "👾"]

        try contexts.forEach { context in
            let expectation = "Hello, \(context)!"
            let context = Context(["self": .string(context)])
            let rendered = try stem.render(template, with: context).string
            XCTAssert(rendered == expectation)
        }
    }

    func testNestedBodyRender() throws {
        let template = try stem.spawnLeaf(named: "nested-body")

        let contextTests: [Node] = [
            try .init(node: ["best-friend": ["name": "World"]]),
            try .init(node: ["best-friend": ["name": "##"]]),
            try .init(node: ["best-friend": ["name": "!^7D0"]])
        ]

        try contextTests.forEach { ctxt in
            let context = Context(ctxt)
            let rendered = try stem.render(template, with: context).string
            let name = ctxt["best-friend", "name"]?.string ?? "[fail]"// (ctxt["best-friend"] as! Dictionary<String, Any>)["name"] as? String ?? "[fail]"
            XCTAssert(rendered == "Hello, \(name)!", "have: \(rendered) want: Hello, \(name)!")
        }
    }

    func testSpawnThrow() throws {
        do {
            _ = try stem.spawnLeaf(raw: "Hello, ^badtag()")
            XCTFail()
        } catch ParseError.tagTemplateNotFound { }
    }

    func testRenderThrowMissingTag() throws {
        do {
            let tag = Test(name: "test", value: nil, shouldRender: true)
            stem.register(tag)
            let leaf = try stem.spawnLeaf(raw: "Hello, ^test()")
            stem.remove(tag)
            _ = try stem.render(leaf, with: Context([]))
            XCTFail()
        } catch ParseError.tagTemplateNotFound { }
    }

    func testRenderNil() throws {
        let tag = Test(name: "nil", value: nil, shouldRender: true)
        stem.register(tag)
        let leaf = try stem.spawnLeaf(raw: "^nil()")
        let rendered = try stem.render(leaf, with: Context([])).string
        XCTAssert(rendered == "")
    }
}
