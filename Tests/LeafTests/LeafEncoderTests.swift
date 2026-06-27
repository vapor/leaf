import Leaf
import LeafKit
import Testing
import VaporTesting

@Suite("LeafEncoder Tests")
struct LeafEncoderTests {
    private func testRender(
        of testLeaf: String,
        context: (some Encodable & Sendable)? = nil,
        expect expectedStatus: HTTPStatus = .ok,
        afterResponse: (TestingHTTPResponse) async throws -> (),
        sourceLocation: SourceLocation = #_sourceLocation()
    ) async throws {
        var test = TestFiles()
        test.files["/foo.leaf"] = testLeaf

        try await withApp { app in
            app.views.use(.leaf)
            app.leaf.sources = .singleSource(test)
            if let context {
                app.get("foo") { try await $0.view.render("foo", context) }
            } else {
                app.get("foo") { try await $0.view.render("foo") }
            }

            try await app.test(.GET, "foo") { res async throws in
                #expect(res.status == expectedStatus, sourceLocation: sourceLocation)
                try await afterResponse(res)
            }
        }
    }

    @Test("empty context")
    func emptyContext() async throws {
        try await self.testRender(of: "Hello!\n", context: Bool?.none) {
            #expect($0.body.string == "Hello!\n")
        }
    }

    @Test("simple scalar context")
    func simpleScalarContext() async throws {
        struct Simple: Codable {
            let value: Int
        }
        
        try await self.testRender(of: "Value #(value)", context: Simple(value: 1)) {
            #expect($0.body.string == "Value 1")
        }
    }
    
    @Test("multi value context")
    func multiValueContext() async throws {
        struct Multi: Codable {
            let value: Int
            let anotherValue: String
        }
        
        try await self.testRender(of: "Value #(value), string #(anotherValue)", context: Multi(value: 1, anotherValue: "one")) {
            #expect($0.body.string == "Value 1, string one")
        }
    }
    
    @Test("array context fails")
    func arrayContextFails() async throws {
        try await self.testRender(of: "[1, 2, 3, 4, 5]", context: [1, 2, 3, 4, 5], expect: .internalServerError) {
            struct Err: Content { let error: Bool, reason: String }
            let errInfo = try $0.content.decode(Err.self)
            #expect(errInfo.error)
            #expect(errInfo.reason.contains("must be dictionaries"))
        }
    }
    
    @Test("nested containers context")
    func nestedContainersContext() async throws {
        struct Nested: Codable         { let deepSixRedOctober: [Int: MoreNested] }
        struct MoreNested: Codable     { let things: [EvenMoreNested] }
        struct EvenMoreNested: Codable { let thing: [String: Double] }

        try await self.testRender(of: "Everything #(deepSixRedOctober)", context: Nested(deepSixRedOctober: [
            1: .init(things: [
                .init(thing: ["a": 1.0, "b": 2.0]),
                .init(thing: ["c": 4.0, "d": 8.0]),
            ]),
            2: .init(things: [
                .init(thing: ["z": 67_108_864.0]),
            ])
        ])) {
            #expect($0.body.string == """
                Everything [1: &quot;[things: &quot;[&quot;[thing: &quot;[a: &quot;1.0&quot;, b: &quot;2.0&quot;]&quot;]&quot;, &quot;[thing: &quot;[c: &quot;4.0&quot;, d: &quot;8.0&quot;]&quot;]&quot;]&quot;]&quot;, 2: &quot;[things: &quot;[&quot;[thing: &quot;[z: &quot;67108864.0&quot;]&quot;]&quot;]&quot;]&quot;]
                """)
        }
    }
    
    @Test("super encoder context")
    func superEncoderContext() async throws {
        struct BetterCallSuperGoodman: Codable {
            let nestedId: Int
            let value: String?
        }

        struct BreakingCodable: Codable {
            let justTheId: Int
            let call: BetterCallSuperGoodman
            let called: BetterCallSuperGoodman

            private enum CodingKeys: String, CodingKey { case id, call }
            init(justTheId: Int, call: BetterCallSuperGoodman, called: BetterCallSuperGoodman) {
                (self.justTheId, self.call, self.called) = (justTheId, call, called)
            }
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: Self.CodingKeys.self)
                self.justTheId = try container.decode(Int.self, forKey: .id)
                self.call = try .init(from: container.superDecoder(forKey: .call))
                self.called = try .init(from: container.superDecoder())
            }
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: Self.CodingKeys.self)
                try container.encode(self.justTheId, forKey: .id)
                try self.call.encode(to: container.superEncoder(forKey: .call))
                try self.called.encode(to: container.superEncoder())
            }
        }
        
        try await self.testRender(of: """
            #(id), or you'd better call:
            #(call)
            unless you called:
            #(super)
            """,
            context: BreakingCodable(
                justTheId: 8675309,
                call: .init(nestedId: 8008, value: "Who R U?"),
                called: .init(nestedId: 1337, value: "Super!")
            )
        ) {
            #expect($0.body.string == """
                8675309, or you'd better call:
                [nestedId: &quot;8008&quot;, value: &quot;Who R U?&quot;]
                unless you called:
                [nestedId: &quot;1337&quot;, value: &quot;Super!&quot;]
                """)
        }
    }
    
    @Test("encode doesn't elide empty containers")
    func encodeDoesntElideEmptyContainers() async throws {
        struct CodableContainersNeedBetterSemantics: Codable {
            let title: String
            let todoList: [String]
            let toundoList: [String: String]
        }
        
        try await self.testRender(of: "#count(todoList)\n#count(toundoList)", context: CodableContainersNeedBetterSemantics(title: "a", todoList: [], toundoList: [:])) {
            #expect($0.body.string == "0\n0")
        }
    }

    @Test("misbehaving encode method works as expected without fatalError()")
    func misbehavingEncodeMethodWorksAsExpectedWithoutFatalError() async throws {
        struct FunkilyEncoded<T: Encodable & Sendable>: Encodable, Sendable {
            private enum CodingKeys: String, CodingKey { case title }

            let title: String
            let subobject: T

            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: Self.CodingKeys.self)
                try container.encode(self.title, forKey: .title)
                try subobject.encode(to: encoder)
            }
        }

        struct Normal: Encodable {
            let thing1: String
            let thing2: String
        }

        try await self.testRender(of: "#(title) #(thing1) #(thing2)", context: FunkilyEncoded(title: "a", subobject: Normal(thing1: "b", thing2: "c"))) {
            #expect($0.body.string == "a b c")
        }
    }
}
