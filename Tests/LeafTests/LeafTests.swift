import Leaf
import LeafKit
import XCTVapor

class LeafTests: XCTestCase {
    func testApplication() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.views.use(.leaf)
        app.leaf.configuration.rootDirectory = projectFolder
        app.leaf.sources = .singleSource(NIOLeafFiles(fileio: app.fileio,
                                                      limits: .default,
                                                      sandboxDirectory: projectFolder,
                                                      viewDirectory: projectFolder))


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
        app.leaf.sources = .singleSource(NIOLeafFiles(fileio: app.fileio,
                                                      limits: .default,
                                                      sandboxDirectory: projectFolder,
                                                      viewDirectory: templateFolder))

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
        Hello #(name) @ #source()
        """

        struct SourceTag: LeafTag {
            func render(_ ctx: LeafContext) throws -> LeafData {
                .string(ctx.request?.url.path ?? "application")
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }

        app.views.use(.leaf)
        app.leaf.configuration.rootDirectory = "/"
        app.leaf.cache.isEnabled = false
        app.leaf.tags["source"] = SourceTag()
        app.leaf.sources = .singleSource(test)

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

        app.get("test-file-with-application-renderer") { req in
            req.application.leaf.renderer.render("foo", [
                "name": "World"
            ])
        }

        try app.test(.GET, "test-file-with-application-renderer") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .html)
            XCTAssertEqual(res.body.string, "Hello World @ application")
        }
    }
    
    func testContextUserInfo() throws {
        var test = TestFiles()
        test.files["/foo.leaf"] = """
        Hello #custom()! @ #source()
        """

        struct CustomTag: LeafTag {
            func render(_ ctx: LeafContext) throws -> LeafData {
                let info = ctx.userInfo["info"] as? String ?? ""
                
                return .string(info)
            }
        }

        struct SourceTag: LeafTag {
            func render(_ ctx: LeafContext) throws -> LeafData {
                .string(ctx.request?.url.path ?? "application")
            }
        }

        let app = Application(.testing)
        defer { app.shutdown() }

        app.views.use(.leaf)
        app.leaf.configuration.rootDirectory = "/"
        app.leaf.cache.isEnabled = false
        app.leaf.tags["custom"] = CustomTag()
        app.leaf.tags["source"] = SourceTag()
        app.leaf.sources = .singleSource(test)
        app.leaf.userInfo["info"] = "World"

        app.get("test-file") { req in
            req.view.render("foo")
        }

        try app.test(.GET, "test-file") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .html)
            XCTAssertEqual(res.body.string, "Hello World! @ /test-file")
        }

        app.get("test-file-with-application-renderer") { req in
            req.application.leaf.renderer.render("foo")
        }

        try app.test(.GET, "test-file-with-application-renderer") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.contentType, .html)
            XCTAssertEqual(res.body.string, "Hello World! @ application")
        }
    }

    func testLeafCacheDisabledInDevelopment() throws {
        let app = Application(.development)
        defer { app.shutdown() }

        app.views.use(.leaf)

        guard let renderer = app.view as? LeafRenderer else {
            XCTFail()
            return
        }

        XCTAssertFalse(renderer.cache.isEnabled)
    }

    func testLeafCacheEnabledInProduction() throws {
        let app = Application(.production)
        defer { app.shutdown() }

        app.views.use(.leaf)

        guard let renderer = app.view as? LeafRenderer else {
            XCTFail()
            return
        }

        XCTAssertTrue(renderer.cache.isEnabled)
    }
}

/// Helper `LeafFiles` struct providing an in-memory thread-safe map of "file names" to "file data"
internal struct TestFiles: LeafSource {
    var files: [String: String]
    var lock: Lock
    
    init() {
        files = [:]
        lock = .init()
    }
    
    public func file(template: String, escape: Bool = false, on eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        var path = template
        if path.split(separator: "/").last?.split(separator: ".").count ?? 1 < 2,
           !path.hasSuffix(".leaf") { path += ".leaf" }
        if !path.hasPrefix("/") { path = "/" + path }
        
        self.lock.lock()
        defer { self.lock.unlock() }
        if let file = self.files[path] {
            var buffer = ByteBufferAllocator().buffer(capacity: file.count)
            buffer.writeString(file)
            return eventLoop.makeSucceededFuture(buffer)
        } else {
            return eventLoop.makeFailedFuture(LeafError(.noTemplateExists(template)))
        }
    }
}

internal var templateFolder: String {
    return projectFolder + "Views/"
}

internal var projectFolder: String {
    let folder = #file.split(separator: "/").dropLast(3).joined(separator: "/")
    return "/" + folder + "/"
}
