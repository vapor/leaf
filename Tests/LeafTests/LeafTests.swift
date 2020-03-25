import Leaf
import XCTVapor

class LeafTests: XCTestCase {
    func testApplication() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.views.use(.leaf)
        app.leaf.cache.isEnabled = false

        app.get("test-file") { req in
            req.view.render(#file, ["foo": "bar"])
        }

        try app.test(.GET, "test-file") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .html)
            // test: #(foo)
            XCTAssertContains(res.body.string, "test: bar")
        }
    }

    func testContextRequest() throws {
        var test = TestFiles()
        test.files["/foo.leaf"] = """
        Hello #(name) @ #path()
        """

        struct RequestPathTag: LeafTag {
            func render(_ ctx: LeafContext) throws -> LeafData {
                .string(ctx.request?.url.path ?? "")
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }

        app.views.use(.leaf)
        app.leaf.configuration.rootDirectory = "/"
        app.leaf.cache.isEnabled = false
        app.leaf.tags["path"] = RequestPathTag()
        app.leaf.files = test

        app.get("test-file") { req in
            req.view.render("foo", [
                "name": "vapor"
            ])
        }

        try app.test(.GET, "test-file") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .html)
            XCTAssertEqual(res.body.string, "Hello vapor @ /test-file")
        }
    }
    
    func testContextUserInfo() throws {
        var test = TestFiles()
        test.files["/foo.leaf"] = """
        Hello #custom()!
        """

        struct CustomTag: LeafTag {
            
            func render(_ ctx: LeafContext) throws -> LeafData {
                let info = ctx.userInfo["info"] as? String ?? ""
                
                return .string(info)
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }

        app.views.use(.leaf)
        app.leaf.configuration.rootDirectory = "/"
        app.leaf.cache.isEnabled = false
        app.leaf.tags["custom"] = CustomTag()
        app.leaf.files = test
        app.leaf.userInfo["info"] = "World"

        app.get("test-file") { req in
            req.view.render("foo", [
                "name": "vapor"
            ])
        }

        try app.test(.GET, "test-file") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .html)
            XCTAssertEqual(res.body.string, "Hello World!")
        }
    }
}

struct TestFiles: LeafFiles {
    var files: [String: String]

    init() {
        files = [:]
    }

    func file(path: String, on eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        if let file = self.files[path] {
            var buffer = ByteBufferAllocator().buffer(capacity: 0)
            buffer.writeString(file)
            return eventLoop.makeSucceededFuture(buffer)
        } else {
            return eventLoop.makeFailedFuture("no test file: \(path)")
        }
    }
}
