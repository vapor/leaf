import Foundation
import Leaf
import LeafKit
import XCTest
import XCTVapor

final class LeafEncoderTests: XCTestCase {
    override class func setUp() {
        // Make dictionary serialization output deterministic
        LeafConfiguration.dictFormatter = { "[\($0.sorted { $0.0 < $1.0 }.map { "\($0): \"\($1)\"" }.joined(separator: ", "))]" }
    }

    private func testRender(
        of testLeaf: String,
        context: (some Encodable & Sendable)? = nil,
        expect expectedStatus: HTTPStatus = .ok,
        afterResponse: (TestingHTTPResponse) async throws -> (),
        file: StaticString = #filePath, line: UInt = #line
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

            try await app.testable().test(.GET, "foo") { res async throws in
                XCTAssertEqual(res.status, expectedStatus, file: file, line: line)
                try await afterResponse(res)
            }
        }
    }
    
    func testEmptyContext() async throws {
        try await testRender(of: "Hello!\n", context: Bool?.none) {
            XCTAssertEqual($0.body.string, "Hello!\n")
        }
    }
    
    func testSimpleScalarContext() async throws {
        struct Simple: Codable {
            let value: Int
        }
        
        try await testRender(of: "Value #(value)", context: Simple(value: 1)) {
            XCTAssertEqual($0.body.string, "Value 1")
        }
    }
    
    func testMultiValueContext() async throws {
        struct Multi: Codable {
            let value: Int
            let anotherValue: String
        }
        
        try await testRender(of: "Value #(value), string #(anotherValue)", context: Multi(value: 1, anotherValue: "one")) {
            XCTAssertEqual($0.body.string, "Value 1, string one")
        }
    }
    
    func testArrayContextFails() async throws {
        try await testRender(of: "[1, 2, 3, 4, 5]", context: [1, 2, 3, 4, 5], expect: .internalServerError) {
            struct Err: Content { let error: Bool, reason: String }
            let errInfo = try $0.content.decode(Err.self)
            XCTAssertEqual(errInfo.error, true)
            XCTAssert(errInfo.reason.contains("must be dictionaries"))
        }
    }
    
    func testNestedContainersContext() async throws {
        struct Nested: Codable         { let deepSixRedOctober: [Int: MoreNested] }
        struct MoreNested: Codable     { let things: [EvenMoreNested] }
        struct EvenMoreNested: Codable { let thing: [String: Double] }

        try await testRender(of: "Everything #(deepSixRedOctober)", context: Nested(deepSixRedOctober: [
            1: .init(things: [
                .init(thing: ["a": 1.0, "b": 2.0]),
                .init(thing: ["c": 4.0, "d": 8.0]),
            ]),
            2: .init(things: [
                .init(thing: ["z": 67_108_864.0]),
            ])
        ])) {
            XCTAssertEqual($0.body.string, """
                Everything [1: "[things: "["[thing: "[a: "1.0", b: "2.0"]"]", "[thing: "[c: "4.0", d: "8.0"]"]"]"]", 2: "[things: "["[thing: "[z: "67108864.0"]"]"]"]"]
                """)
        }
    }
    
    func testSuperEncoderContext() async throws {
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
        
        try await testRender(of: """
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
            XCTAssertEqual($0.body.string, """
                8675309, or you'd better call:
                [nestedId: "8008", value: "Who R U?"]
                unless you called:
                [nestedId: "1337", value: "Super!"]
                """)
        }
    }
    
    func testEncodeDoesntElideEmptyContainers() async throws {
        struct CodableContainersNeedBetterSemantics: Codable {
            let title: String
            let todoList: [String]
            let toundoList: [String: String]
        }
        
        try await testRender(of: "#count(todoList)\n#count(toundoList)", context: CodableContainersNeedBetterSemantics(title: "a", todoList: [], toundoList: [:])) {
            XCTAssertEqual($0.body.string, "0\n0")
        }
    }
}
