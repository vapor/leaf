import Leaf
import XCTVapor

class LeafTests: XCTestCase {
    func testApplication() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.views.use(.leaf)
        app.leaf.configuration.rootDirectory = projectFolder
        app.leaf.cache.isEnabled = false

        app.get("test-file") { req in
            req.view.render("Tests/LeafTests/LeafTests.swift", ["foo": "bar"])
        }

        try app.test(.GET, "test-file") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .html)
            // test: #(foo)
            XCTAssertContains(res.body.string, "test: bar")
        }
    }
    
    func testSandboxing() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.views.use(.leaf)
        app.leaf.configuration.rootDirectory = templateFolder
        app.leaf.files = NIOLeafFiles(fileio: app.fileio,
                                      limits: .default,
                                      sandboxDirectory: projectFolder,
                                      viewDirectory: templateFolder)

        app.get("hello") { req in
            req.view.render("hello")
        }
        
        app.get("allowed") { req in
            req.view.render("../hello")
        }
        
        app.get("sandboxed") { req in
            req.view.render("../../hello")
        }

        try app.test(.GET, "hello") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .html)
            XCTAssertEqual(res.body.string, "Hello, world!\n")
        }
        
        try app.test(.GET, "allowed") { res in
            XCTAssertEqual(res.status, .internalServerError)
            XCTAssert(res.body.string.contains("noTemplateExists"))
        }
        
        try app.test(.GET, "sandboxed") { res in
            XCTAssertEqual(res.status, .internalServerError)
            XCTAssert(res.body.string.contains("Attempted to escape sandbox"))
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

internal struct TestFiles: LeafSource {
    var files: [String: String]

    init() {
        files = [:]
    }

    func file(template: String, escape: Bool = false, on eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        if let file = self.files[expand(template)] {
            var buffer = ByteBufferAllocator().buffer(capacity: 0)
            buffer.writeString(file)
            return eventLoop.makeSucceededFuture(buffer)
        } else {
            return eventLoop.makeFailedFuture("no test file: \(template)")
        }
    }
    
    private func expand(_ template: String) -> String {
        var path = template
        // ignore files that already have a type
        if path.split(separator: "/").last?.split(separator: ".").count ?? 1 < 2  , !path.hasSuffix(".leaf") {
            path += ".leaf"
        }

        if !path.hasPrefix("/") {
            path = "/" + path
        }
        return path
    }
}

internal var templateFolder: String {
    return projectFolder + "Views/"
}

internal var projectFolder: String {
    let folder = #file.split(separator: "/").dropLast(3).joined(separator: "/")
    return "/" + folder + "/"
}
