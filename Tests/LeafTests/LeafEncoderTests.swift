import Leaf
import LeafKit
import XCTVapor
import Foundation

final class LeafEncoderTests: XCTestCase {
    private func testRender(
        of testLeaf: String,
        context: Encodable? = nil,
        expect expectedStatus: HTTPStatus = .ok,
        afterResponse: (XCTHTTPResponse) throws -> (),
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        var test = TestFiles()
        test.files["/foo.leaf"] = testLeaf
        
        let app = Application(.testing)
        defer { app.shutdown() }
        app.views.use(.leaf)
        app.leaf.sources = .singleSource(test)
        if let context = context {
            func _defRoute<T: Encodable>(context: T) { app.get("foo") { $0.view.render("foo", context) } }
            _openExistential(context, do: _defRoute(context:))
        } else {
            app.get("foo") { $0.view.render("foo") }
        }
        
        try app.test(.GET, "foo") { res in
            XCTAssertEqual(res.status, expectedStatus, file: file, line: line)
            try afterResponse(res)
        }
        
    }
    
    func testEmptyContext() throws {
        try testRender(of: "Hello!\n") {
            XCTAssertEqual($0.body.string, "Hello!\n")
        }
    }
    
    func testSimpleScalarContext() throws {
        struct Simple: Codable {
            let value: Int
        }
        
        try testRender(of: "Value #(value)", context: Simple(value: 1)) {
            XCTAssertEqual($0.body.string, "Value 1")
        }
    }
    
    func testMultiValueContext() throws {
        struct Multi: Codable {
            let value: Int
            let anotherValue: String
        }
        
        try testRender(of: "Value #(value), string #(anotherValue)", context: Multi(value: 1, anotherValue: "one")) {
            XCTAssertEqual($0.body.string, "Value 1, string one")
        }
    }
    
    func testArrayContextFails() throws {
        try testRender(of: "[1, 2, 3, 4, 5]", context: [1, 2, 3, 4, 5], expect: .internalServerError) {
            struct Err: Content { let error: Bool, reason: String }
            let errInfo = try $0.content.decode(Err.self)
            XCTAssertEqual(errInfo.error, true)
            XCTAssert(errInfo.reason.contains("must be dictionaries"))
        }
    }
    
    func testNestedContainersContext() throws {
        _ = try XCTUnwrap(ProcessInfo.processInfo.environment["SWIFT_DETERMINISTIC_HASHING"]) // required for this test to work
        
        struct Nested: Codable         { let deepSixRedOctober: [Int: MoreNested] }
        struct MoreNested: Codable     { let things: [EvenMoreNested] }
        struct EvenMoreNested: Codable { let thing: [String: Double] }
        
        try testRender(of: "Everything #(deepSixRedOctober)", context: Nested(deepSixRedOctober: [
            1: .init(things: [
                .init(thing: ["a": 1.0, "b": 2.0]),
                .init(thing: ["c": 4.0, "d": 8.0])
            ]),
            2: .init(things: [
                .init(thing: ["z": 67_108_864.0])
            ])
        ])) {
            XCTAssertEqual($0.body.string, """
                Everything [2: "[things: "["[thing: "[z: "67108864.0"]"]"]"]", 1: "[things: "["[thing: "[a: "1.0", b: "2.0"]"]", "[thing: "[d: "8.0", c: "4.0"]"]"]"]"]
                """)
        }
    }
    
    func testSuperEncoderContext() throws {
        _ = try XCTUnwrap(ProcessInfo.processInfo.environment["SWIFT_DETERMINISTIC_HASHING"]) // required for this test to work

        struct BetterCallSuperGoodman: Codable {
            let nestedId: Int
            let value: String?
        }

        struct BreakingCodable: Codable {
            let justTheId: Int
            let call: BetterCallSuperGoodman
            
            private enum CodingKeys: String, CodingKey { case id, call }
            init(justTheId: Int, call: BetterCallSuperGoodman) {
                self.justTheId = justTheId
                self.call = call
            }
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: Self.CodingKeys.self)
                self.justTheId = try container.decode(Int.self, forKey: .id)
                self.call = try .init(from: container.superDecoder(forKey: .call))
            }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: Self.CodingKeys.self)
                try container.encode(self.justTheId, forKey: .id)
                try self.call.encode(to: container.superEncoder(forKey: .call))
            }
        }
        
        try testRender(of: """
            KHAAAAAAAAN!!!!!!!!!
            
            #(id), or you'd better call:
            
            #(call)
            """, context: BreakingCodable(justTheId: 8675309, call: .init(nestedId: 8008, value: "Who R U?"))
        ) {
            XCTAssertEqual($0.body.string, """
                KHAAAAAAAAN!!!!!!!!!
                
                8675309, or you'd better call:
                
                [nestedId: "8008", value: "Who R U?"]
                """)
        }
    }
}
