import Core
import Foundation
import XCTest
@testable import template

class FuzzyAccessibleTests: XCTestCase {
    func testSingleDictionary() {
        let object: [String: Any] = [
            "hello": "world"
        ]
        let result = object.get(key: "hello")
        XCTAssertNotNil(result)
        guard let unwrapped = result else { return }
        XCTAssert("\(unwrapped)" == "world")
    }

    func testSingleArray() {
        let object: [Any] = [
            "hello",
            "world"
        ]

        let assertions: [String: String] = [
            "0": "Optional(\"hello\")",
            "1": "Optional(\"world\")",
            "2": "nil",
            "notidx": "nil"
        ]
        assertions.forEach { key, expectation in
            let result = object.get(key: key)
            print("\(result)")
            XCTAssert("\(result)" == expectation)
        }
    }

    func testLinkedDictionary() {
        let object: [String: Any] = [
            "hello": [
                "subpath": [
                    "to": [
                        "value": "Hello!"
                    ]
                ]
            ]
        ]

        let result = object.get(path: "hello.subpath.to.value")
        XCTAssertNotNil(result)
        guard let unwrapped = result else { return }
        XCTAssert("\(unwrapped)" == "Hello!")
    }

    func testLinkedArray() {
        let object: [Any] = [
            // 0
            [Any](arrayLiteral:
                [Any](),
                // 1
                [Any](arrayLiteral:
                    [Any](),
                    [Any](),
                     //2
                    [Any](arrayLiteral:
                        // 0
                        [Any](arrayLiteral:
                            "",
                            "",
                            "",
                            "Hello!" // 3
                        )
                    )
                )
            )
        ]

        let result = object.get(path: "0.1.2.0.3")
        XCTAssertNotNil(result)
        guard let unwrapped = result else { return }
        XCTAssert("\(unwrapped)" == "Hello!", "have: \(unwrapped), want: Hello!")
    }

    func testFuzzyLeaf() throws {
        let raw = "Hello, #(path.to.person.0.name)!"
        let context: [String: Any] = [
            "path": [
                "to": [
                    "person": [
                        ["name": "World"]
                    ]
                ]
            ]
        ]

        let template = try Leaf(raw: raw)
        let filler = Scope(context)
        let rendered = try Stem().render(template, with: filler).string
        let expectation = "Hello, World!"
        XCTAssert(rendered == expectation)
    }
}

class ScopeTests: XCTestCase {
    func testBasic() throws {
        let stem = Stem()
        let template = try stem.loadLeaf(raw: "Hello, #(name)!")
        let context: [String: String] = ["name": "World"]
        let filler = Scope(context)
        do {
            let rendered = try stem.render(template, with: filler).string
        let expectation = "Hello, World!"
            XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
        } catch { XCTFail("\(error)") }
    }

    func testNested() throws {
        let raw = "#(best-friend) { Hello, #(self.name)! }"
        let stem = Stem()
        let template = try stem.loadLeaf(raw: raw)
        print("Components: \(template.components)")
        let filler = Scope(["best-friend": ["name": "World"]])
        let rendered = try stem.render(template, with: filler).string
        XCTAssert(rendered == "Hello, World!")
    }

    func testLoop() throws {
        let raw = "#loop(friends, \"friend\") { Hello, #(friend)! }"
        let stem = Stem()
        let template = try stem.loadLeaf(raw: raw)
        let filler = Scope(["friends": ["a", "b", "c", "#loop"]])
        let rendered = try stem.render(template, with: filler).string
        let expectation =  "Hello, a!\nHello, b!\nHello, c!\nHello, #loop!\n"
        XCTAssert(rendered == expectation)
    }

    func testNamedInner() throws {
        let raw = "#(name) { #(name) }" // redundant, but should render as an inner stem
        let stem = Stem()
        let template = try stem.loadLeaf(raw: raw)
        let filler = Scope(["name": "foo"])
        let rendered = try stem.render(template, with: filler).string
        let expectation = "foo"
        XCTAssert(rendered == expectation)
    }

    func testDualContext() throws {
        let raw = "Let's render #(friend) { #(name) is friends with #(friend.name) } "
        let stem = Stem()
        let template = try stem.loadLeaf(raw: raw)
        let filler = Scope(["name": "Foo", "friend": ["name": "Bar"]])
        let rendered = try stem.render(template, with: filler).string
        let expectation = "Let's render Foo is friends with Bar"
        XCTAssert(rendered == expectation, "have: *\(rendered)* want: *\(expectation)*")
    }

    func testMultiScope() throws {
        let raw = "#(a) { #(self.b) { #(self.c) { #(self.path.1) } } }"
        let stem = Stem()
        let template = try stem.loadLeaf(raw: raw)
        let filler = Scope(["a": ["b": ["c": ["path": ["array-variant", "HEllo"]]]]])
        let rendered = try stem.render(template, with: filler).string
        let expectation = "HEllo"
        XCTAssert(rendered == expectation)
    }

    func testIfChain() throws {
        let raw = "#if(key-zero) { Hi, A! } ##if(key-one) { Hi, B! } ##else() { Hi, C! }"
        let stem = Stem()
        let template = try stem.loadLeaf(raw: raw)
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
            let filler = Scope([key: bool])
            let rendered = try stem.render(template, with: filler).string
            XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
        }
    }
}

class FilterTests: XCTestCase {
    func testBasic() throws {
        let raw = "#(name) { #uppercased(self) }"
        // let raw = "#uppercased(name)"
        let stem = Stem()
        let template = try stem.loadLeaf(raw: raw)
        let filler = Scope(["name": "hi"])
        let rendered = try stem.render(template, with: filler).string
        let expectation = "HI"
        XCTAssert(rendered == expectation)
    }
}

class IncludeTests: XCTestCase {
    func testBasicInclude() throws {
        let stem = Stem()
        let template = try stem.loadLeaf(named: "include-base")
        // let template = try loadLeaf(named: "include-base")
        let filler = Scope(["name": "World"])
        let rendered = try stem.render(template, with: filler).string
        let expectation = "Leaf included: Hello, World!"
        XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
    }
}

class LeafLoadingTests: XCTestCase {
    func testBasicRawOnly() throws {
        let template = try loadLeaf(named: "template-basic-raw")
        XCTAssert(template.components ==  [.raw("Hello, World!".bytes)])
    }

    /* Failing non-existent commands
    func testBasicInstructions() throws {
        do {
        let template = try loadLeaf(named: "template-basic-tagTemplates-no-body")
        // #custom(two, variables, "and one constant")
        let tagTemplate = try Leaf.Component.Instruction(
            name: "custom",
            parameters: [.variable("two"), .variable("variables"), .constant("and one constant")],
            body: String?.none
        )

        let expectation: [Leaf.Component] = [
            .raw("Some raw text here. ".bytes),
            .tagTemplate(tagTemplate)
        ]
        XCTAssert(template.components ==  expectation, "have: \(template.components) want: \(expectation)")
        } catch { XCTFail("E: \(error)") }
    }

    func testBasicNested() throws {
        /*
            Here's a basic template and, #command(parameter) {
                now we're in the body, which is ALSO a #template("constant") {
                    and a third sub template with a #(variable)
                }
            }

        */
        let template = try loadLeaf(named: "template-basic-nested")

        let command = try Leaf.Component.Instruction(
            name: "command",
            // TODO: `.variable(name: `
            parameters: [.variable("parameter")],
            body: "now we're in the body, which is ALSO a #template(\"constant\") {\n\tand a third sub template with a #(variable)\n\t}"
        )

        let expectation: [Leaf.Component] = [
            .raw("Here's a basic template and, ".bytes),
            .tagTemplate(command)
        ]
        XCTAssert(template.components ==  expectation)
    }
    */
}

class LeafRenderTests: XCTestCase {
    func testBasicRender() throws {
        let template = try loadLeaf(named: "basic-render")
        let contexts = ["a", "ab9***", "ajcm301kc,s--11111", "World", "👾"]

        try contexts.forEach { context in
            let expectation = "Hello, \(context)!"
            let filler = Scope(["self": context])
            let rendered = try Stem().render(template, with: filler).string
            XCTAssert(rendered == expectation)
        }
    }

    func testNestedBodyRender() throws {
        let template = try loadLeaf(named: "nested-body")

        let contextTests: [[String: Any]] = [
            ["best-friend": ["name": "World"]],
            ["best-friend": ["name": "##"]],
            ["best-friend": ["name": "!*7D0"]]
        ]

        try contextTests.forEach { ctxt in
            let filler = Scope(ctxt)
            let rendered = try Stem().render(template, with: filler).string
            let name = (ctxt["best-friend"] as! Dictionary<String, Any>)["name"] as? String ?? "[fail]"
            XCTAssert(rendered == "Hello, \(name)!", "have: \(rendered) want: Hello, \(name)!")
        }
    }
}

class LoopTests: XCTestCase {
    func testBasicLoop() throws {
        let template = try loadLeaf(named: "basic-loop")

        let context: [String: [Any]] = [
            "friends": [
                "asdf",
                "🐌",
                "8***z0-1",
                12
            ]
        ]
        let filler = Scope(context)
        let expectation = "Hello, asdf\nHello, 🐌\nHello, 8***z0-1\nHello, 12\n"
        let rendered = try Stem().render(template, with: filler).string
        XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
    }

    func testComplexLoop() throws {
        let context: [String: Any] = [
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
        ]

        let template = try loadLeaf(named: "complex-loop")
        let filler = Scope(context)
        let rendered = try Stem().render(template, with: filler).string
        let expectation = "<li><b>Venus</b>: 12345</li>\n<li><b>Pluto</b>: 888</li>\n<li><b>Mercury</b>: 9000</li>\n"
        XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
    }
}

class IfTests: XCTestCase {
    func testBasicIf() throws {
        let template = try loadLeaf(named: "basic-if-test")

        let context = ["say-hello": true]
        let filler = Scope(context)
        let rendered = try Stem().render(template, with: filler).string
        let expectation = "Hello, there!"
        XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
    }

    func testBasicIfFail() throws {
        let template = try loadLeaf(named: "basic-if-test")

        let context = ["say-hello": false]
        let filler = Scope(context)
        let rendered = try Stem().render(template, with: filler).string
        let expectation = ""
        XCTAssert(rendered == expectation, "have: \(rendered), want: \(expectation)")
    }

    func testBasicIfElse() throws {
        let template = try loadLeaf(named: "basic-if-else")

        let helloContext: [String: Any] = [
            "entering": true,
            "friend-name": "World"
        ]
        let helloScope = Scope(helloContext)
        let renderedHello = try Stem().render(template, with: helloScope).string
        let expectedHello = "Hello, World!"
        XCTAssert(renderedHello == expectedHello, "have: \(renderedHello) want: \(expectedHello)")

        let goodbyeContext: [String: Any] = [
            "entering": false,
            "friend-name": "World"
        ]
        let goodbyeScope = Scope(goodbyeContext)
        let renderedGoodbye = try Stem().render(template, with: goodbyeScope).string
        let expectedGoodbye = "Goodbye, World!"
        XCTAssert(renderedGoodbye == expectedGoodbye, "have: \(renderedGoodbye) want: \(expectedGoodbye)")
    }

    func testNestedIfElse() throws {
        let template = try loadLeaf(named: "nested-if-else")
        let expectations: [(input: [String: Any], expectation: String)] = [
            (input: ["a": true], expectation: "Got a."),
            (input: ["b": true], expectation: "Got b."),
            (input: ["c": true], expectation: "Got c."),
            (input: ["d": true], expectation: "Got d."),
            (input: [:], expectation: "Got e.")
        ]

        try expectations.forEach { input, expectation in
            let filler = Scope(input)
            let rendered = try Stem().render(template, with: filler).string
            XCTAssert(rendered == expectation, "have: \(rendered) want: \(expectation)")
        }
    }
}
