import Foundation
import XCTest
@testable import Leaf

class ContextTests: XCTestCase {
    static let allTests = [
        ("testBasic", testBasic),
        ("testNested", testNested),
        ("testLoop", testLoop),
        ("testNamedInner", testNamedInner),
        ("testDualContext", testDualContext),
        ("testMultiContext", testMultiContext),
        ("testIfChain", testIfChain),
        ("testNestedComplex", testNestedComplex),
    ]

    func testBasic() throws {
        let template = try stem.spawnLeaf(raw: "Hello, ^(name)!")
        let context = try Node(node: ["name": "World"])
        let loadable = Context(context)
        let rendered = try stem.render(template, with: loadable).string
        let expectation = "Hello, World!"
        XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
    }

    func testNested() throws {
        let raw = "^(best-friend) { Hello, ^(self.name)! }"
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["best-friend": ["name": "World"]])
        let rendered = try stem.render(template, with: context).string
        XCTAssert(rendered == "Hello, World!")
    }

    func testLoop() throws {
        let raw = "^loop(friends, \"friend\") { Hello, ^(friend)! }"
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["friends": ["a", "b", "c", "^loop"]])
        let rendered = try stem.render(template, with: context).string
        let expectation =  "Hello, a!\nHello, b!\nHello, c!\nHello, ^loop!\n"
        XCTAssert(rendered == expectation)
    }

    func testNamedInner() throws {
        let raw = "^(name) { ^(name) }" // redundant, but should render as an inner stem
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["name": "foo"])
        let rendered = try stem.render(template, with: context).string
        let expectation = "foo"
        XCTAssert(rendered == expectation)
    }

    func testDualContext() throws {
        let raw = "Let's render ^(friend) { ^(name) is friends with ^(friend.name) } "
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["name": "Foo", "friend": ["name": "Bar"]])
        let rendered = try stem.render(template, with: context).string
        let expectation = "Let's render Foo is friends with Bar"
        XCTAssertEqual(rendered, expectation)
    }

    func testMultiContext() throws {
        let raw = "^(a) { ^(self.b) { ^(self.c) { ^(self.path.1) } } }"
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["a": ["b": ["c": ["path": ["array-variant", "HEllo"]]]]])
        let rendered = try stem.render(template, with: context).string
        let expectation = "HEllo"
        XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
    }

    func testIfChain() throws {
        let raw = "^if(key-zero) { Hi, A! } ^^if(key-one) { Hi, B! } ^^else() { Hi, C! }"
        let template = try stem.spawnLeaf(raw: raw)
        let cases: [(key: String, bool: Bool, expectation: String)] = [
            ("key-zero", true, "Hi, A!"),
            ("key-zero", false, "Hi, C!"),
            ("key-one", true, "Hi, B!"),
            ("key-one", false, "Hi, C!"),
            ("s••z", true, "Hi, C!"),
            ("$º–%,🍓", true, "Hi, C!"),
            ("]", true, "Hi, C!"),
            ]

        try cases.forEach { key, bool, expectation in
            let context = Context([key: .bool(bool)])
            let rendered = try stem.render(template, with: context).string
            XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
        }
    }

    func testNestedComplex() throws {
        let raw = "Hello, ^(path.to.person.0.name)!"
        let context = try Node(node:[
            "path": [
                "to": [
                    "person": [
                        ["name": "World"]
                    ]
                ]
            ]
            ])

        let template = try stem.spawnLeaf(raw: raw)
        let loadable = Context(context)
        let rendered = try stem.render(template, with: loadable).string
        let expectation = "Hello, World!"
        XCTAssert(rendered == expectation)
    }
}
