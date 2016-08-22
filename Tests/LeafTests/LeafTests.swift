import Foundation
import XCTest
@testable import Leaf

let stem = Stem()

class Performance: XCTestCase {
    func testLeaf() throws {
        let stem = Stem()
        let raw = "Hello, #(name)!"
        let expectation = "Hello, World!".bytes
        let template = try Leaf(raw: raw)
        let ctxt = Context(["name": "World"])
        measure {
            try! (1...500).forEach { _ in
                let rendered = try stem.render(template, with: ctxt)
                XCTAssert(rendered == expectation)
            }
        }
    }

    func testContextGet() throws {
        let ctxt = Context(["name": "World"])
        measure {
            (1...500).forEach { _ in
                _ = ctxt.get(path: "name")
            }
        }
    }

    func testContextPush() throws {
        let ctxt = Context(["name": "World"])
        measure {
            (1...500).forEach { _ in
                _ = ctxt.push(["self": "..."])
                defer { ctxt.pop() }
            }
        }
    }

    func testLeafB() throws {
        let stem = Stem()
        let raw = [String](repeating: "Hello, #(name)!", count: 1000).joined(separator: ", ")
        let expectation = [String](repeating: "Hello, World!", count: 1000).joined(separator: ", ").bytes
        let template = try Leaf(raw: raw)
        let ctxt = Context(["name": "World"])
        measure {
            try! (1...5).forEach { _ in
                let rendered = try stem.render(template, with: ctxt)
                XCTAssert(rendered == expectation)
            }
        }
    }
}


class LinkVsArray: XCTestCase {
    func testArray() {
        var array: [Node] = []
        measure {
            (1...500).forEach { _ in
                array.insert(["self": "..."], at: 0)
                defer { array.removeFirst() }
            }
        }
    }

    func testList() {
        var list = List<Node>()
        measure {
            (1...500).forEach { _ in
                list.insertAtTip(["self": "..."])
                defer { list.removeTip() }
            }
        }
    }

    func testIterateArray() {
        let array = [Int](repeating: 0, count: 100)
        measure {
            (1...5000).forEach { _ in
                array.forEach { _ in }
            }
        }
    }

    func testIterateList() {
        let array = [Int](repeating: 0, count: 100)
        let list = List(array)
        measure {
            (1...5000).forEach { _ in
                list.forEach { _ in }
            }
        }
    }
}

class FuzzyAccessibleTests: XCTestCase {
    func testFuzzyLeaf() throws {
        let raw = "Hello, #(path.to.person.0.name)!"
        let context = try Node(node:[
            "path": [
                "to": [
                    "person": [
                        ["name": "World"]
                    ]
                ]
            ]
        ])

        let template = try Leaf(raw: raw)
        let loadable = Context(context)
        let rendered = try Stem().render(template, with: loadable).string
        let expectation = "Hello, World!"
        XCTAssert(rendered == expectation)
    }
}

class ContextTests: XCTestCase {
    func testBasic() throws {
        let stem = Stem()
        let template = try stem.spawnLeaf(raw: "Hello, #(name)!")
        let context = try Node(node: ["name": "World"])
        let loadable = Context(context)
        let rendered = try stem.render(template, with: loadable).string
        let expectation = "Hello, World!"
        XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
    }

    func testNested() throws {
        let raw = "#(best-friend) { Hello, #(self.name)! }"
        let stem = Stem()
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["best-friend": ["name": "World"]])
        let rendered = try stem.render(template, with: context).string
        XCTAssert(rendered == "Hello, World!")
    }

    func testLoop() throws {
        let raw = "#loop(friends, \"friend\") { Hello, #(friend)! }"
        let stem = Stem()
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["friends": ["a", "b", "c", "#loop"]])
        let rendered = try stem.render(template, with: context).string
        let expectation =  "Hello, a!\nHello, b!\nHello, c!\nHello, #loop!\n"
        XCTAssert(rendered == expectation)
    }

    func testNamedInner() throws {
        let raw = "#(name) { #(name) }" // redundant, but should render as an inner stem
        let stem = Stem()
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["name": "foo"])
        let rendered = try stem.render(template, with: context).string
        let expectation = "foo"
        XCTAssert(rendered == expectation)
    }

    func testDualContext() throws {
        let raw = "Let's render #(friend) { #(name) is friends with #(friend.name) } "
        let stem = Stem()
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["name": "Foo", "friend": ["name": "Bar"]])
        let rendered = try stem.render(template, with: context).string
        let expectation = "Let's render Foo is friends with Bar"
        XCTAssert(rendered == expectation, "have: *\(rendered)* want: *\(expectation)*")
    }

    func testMultiContext() throws {
        let raw = "#(a) { #(self.b) { #(self.c) { #(self.path.1) } } }"
        let stem = Stem()
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["a": ["b": ["c": ["path": ["array-variant", "HEllo"]]]]])
        let rendered = try stem.render(template, with: context).string
        let expectation = "HEllo"
        XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
    }

    func testIfChain() throws {
        let raw = "#if(key-zero) { Hi, A! } ##if(key-one) { Hi, B! } ##else() { Hi, C! }"
        let stem = Stem()
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
}

class FilterTests: XCTestCase {
    func testBasic() throws {
        let raw = "#(name) { #uppercased(self) }"
        // let raw = "#uppercased(name)"
        let stem = Stem()
        let template = try stem.spawnLeaf(raw: raw)
        let context = Context(["name": "hi"])
        let rendered = try stem.render(template, with: context).string
        let expectation = "HI"
        XCTAssert(rendered == expectation)
    }
}

class IncludeTests: XCTestCase {
    func testBasicInclude() throws {
        let stem = Stem()
        let template = try stem.spawnLeaf(named: "include-base")
        // let template = try spawnLeaf(named: "include-base")
        let context = Context(["name": "World"])
        let rendered = try stem.render(template, with: context).string
        let expectation = "Leaf included: Hello, World!"
        XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
    }
}

class LeafRenderTests: XCTestCase {
    func testBasicRender() throws {
        let template = try stem.spawnLeaf(named: "basic-render")
        let contexts = ["a", "ab9***", "ajcm301kc,s--11111", "World", "👾"]

        try contexts.forEach { context in
            let expectation = "Hello, \(context)!"
            let context = Context(["self": .string(context)])
            let rendered = try Stem().render(template, with: context).string
            XCTAssert(rendered == expectation)
        }
    }

    func testNestedBodyRender() throws {
        let template = try stem.spawnLeaf(named: "nested-body")

        let contextTests: [Node] = [
            try .init(node: ["best-friend": ["name": "World"]]),
            try .init(node: ["best-friend": ["name": "##"]]),
            try .init(node: ["best-friend": ["name": "!*7D0"]])
        ]

        try contextTests.forEach { ctxt in
            let context = Context(ctxt)
            let rendered = try Stem().render(template, with: context).string
            let name = ctxt["best-friend", "name"]?.string ?? "[fail]"// (ctxt["best-friend"] as! Dictionary<String, Any>)["name"] as? String ?? "[fail]"
            XCTAssert(rendered == "Hello, \(name)!", "have: \(rendered) want: Hello, \(name)!")
        }
    }
}

class LoopTests: XCTestCase {
    func testBasicLoop() throws {
        let template = try stem.spawnLeaf(named: "basic-loop")

        let context = try Node(node: [
            "friends": [
                "asdf",
                "🐌",
                "8***z0-1",
                12
            ]
        ])
        let loadable = Context(context)
        let expectation = "Hello, asdf\nHello, 🐌\nHello, 8***z0-1\nHello, 12\n"
        let rendered = try Stem().render(template, with: loadable).string
        XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
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
        let rendered = try Stem().render(template, with: loadable).string
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

class IfTests: XCTestCase {
    func testBasicIf() throws {
        let template = try stem.spawnLeaf(named: "basic-if-test")

        let context = try Node(node: ["say-hello": true])
        let loadable = Context(context)
        let rendered = try Stem().render(template, with: loadable).string
        let expectation = "Hello, there!"
        XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
    }

    func testBasicIfFail() throws {
        let template = try stem.spawnLeaf(named: "basic-if-test")

        let context = try Node(node: ["say-hello": false])
        let loadable = Context(context)
        let rendered = try Stem().render(template, with: loadable).string
        let expectation = ""
        XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
    }

    func testBasicIfElse() throws {
        let template = try stem.spawnLeaf(named: "basic-if-else")

        let helloContext = try Node(node: [
            "entering": true,
            "friend-name": "World"
        ])
        let hello = Context(helloContext)
        let renderedHello = try Stem().render(template, with: hello).string
        let expectedHello = "Hello, World!"
        XCTAssert(renderedHello == expectedHello, "have: \(renderedHello) want: \(expectedHello)")

        let goodbyeContext = try Node(node: [
            "entering": false,
            "friend-name": "World"
        ])
        let goodbye = Context(goodbyeContext)
        let renderedGoodbye = try Stem().render(template, with: goodbye).string
        let expectedGoodbye = "Goodbye, World!"
        XCTAssert(renderedGoodbye == expectedGoodbye, "have: \(renderedGoodbye) want: \(expectedGoodbye)")
    }

    func testNestedIfElse() throws {
        let template = try stem.spawnLeaf(named: "nested-if-else")
        let expectations: [(input: Node, expectation: String)] = [
            (input: ["a": true], expectation: "Got a."),
            (input: ["b": true], expectation: "Got b."),
            (input: ["c": true], expectation: "Got c."),
            (input: ["d": true], expectation: "Got d."),
            (input: [:], expectation: "Got e.")
        ]

        try expectations.forEach { input, expectation in
            let context = Context(input)
            let rendered = try Stem().render(template, with: context).string
            XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
        }
    }
}

class VariableTests: XCTestCase {
    func testVariable() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #(name)!")
        let context = Context(["name": "World"])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "Hello, World!")
    }

    func testVariableThrows() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #(name, location)!")
        let context = Context([:])
        do {
            _ = try stem.render(leaf, with: context).string
            XCTFail("Expected error")
        } catch Variable.Error.expectedOneArgument { }
    }

    func testVariableEscape() throws {
        // All tokens are parsed, this tests an escape mechanism to introduce explicit.
        let leaf = try stem.spawnLeaf(raw: "#()#(hashtag)!")
        let context = Context(["hashtag": "leafRules"])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "#leafRules!")
    }

    func testConstant() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #(\"World\")!")
        let context = Context([:])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "Hello, World!")
    }
}

class UppercasedTests: XCTestCase {
    func testUppercased() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #uppercased(name)!")
        let context = Context(["name": "World"])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "Hello, WORLD!")
    }

    func testInvalidArgumentCount() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #uppercased()!")
        let context = Context([:])
        do {
            _ = try stem.render(leaf, with: context).string
            XCTFail("Expected error")
        } catch Uppercased.Error.expectedOneArgument {}
    }

    func testInvalidType() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello, #uppercased(name)!")
        let context = Context(["name": ["invalid", "type", "array"]])
        do {
            _ = try stem.render(leaf, with: context).string
            XCTFail("Expected error")
        } catch Uppercased.Error.expectedStringArgument {}
    }

    func testNil() throws {
        let leaf = try stem.spawnLeaf(raw: "Hello #uppercased(name)")
        let context = Context([:])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "Hello ")
    }

    func testUnwrapNil() throws {
        let leaf = try stem.spawnLeaf(raw: "#uppercased(name) { Hello, #(self)! }")
        let context = Context(["name": "World"])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "Hello, WORLD!")
    }

    func testUnwrapNilEmpty() throws {
        let leaf = try stem.spawnLeaf(raw: "#uppercased(name) { Hello, #(self)! }")
        let context = Context([:])
        let rendered = try stem.render(leaf, with: context).string
        XCTAssert(rendered == "")
    }
}
