import Leaf
import LeafKit
import NIOConcurrencyHelpers
import Testing
import VaporTesting

@Suite("Leaf tests")
struct LeafTests {
    #if !os(Android)
    @Test("application")
    func application() async throws {
        try await withApp { app in
            app.views.use(.leaf)
            app.leaf.configuration.rootDirectory = projectFolder
            app.leaf.sources = .singleSource(NIOLeafFiles(
                fileio: app.fileio,
                limits: .default,
                sandboxDirectory: projectFolder,
                viewDirectory: templateFolder
            ))
            app.get("test-file") { req in
                try await req.view.render("foo", ["foo": "bar"])
            }

            try await app.test(.GET, "test-file") { res async throws in
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .html)
                // test: #(foo)
                #expect(res.body.string.contains("test: bar"))
            }
        }
    }

    @Test("sandboxing")
    func sandboxing() async throws {
        try await withApp { app in
            app.views.use(.leaf)
            app.leaf.configuration.rootDirectory = templateFolder
            app.leaf.sources = .singleSource(NIOLeafFiles(
                fileio: app.fileio,
                limits: .default,
                sandboxDirectory: projectFolder,
                viewDirectory: templateFolder
            ))

            app.get("hello") { req in
                try await req.view.render("hello")
            }
            app.get("allowed") { req in
                try await req.view.render("../hello")
            }
            app.get("sandboxed") { req in
                try await req.view.render("../../../../hello")
            }

            try await app.test(.GET, "hello") { res async in
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .html)
                #expect(res.body.string == "Hello, world!\n")
            }

            try await app.test(.GET, "allowed") { res async in
                #expect(res.status == .internalServerError)
                #expect(res.body.string.contains("No template found"))
            }

            try await app.test(.GET, "sandboxed") { res async in
                #expect(res.status == .internalServerError)
                #expect(res.body.string.contains("Attempted to escape sandbox"))
            }
        }
    }
    #endif

    @Test("context request")
    func contextRequest() async throws {
        var test = TestFiles()
        test.files["/foo.leaf"] = """
            Hello #(name) @ #source()
            """

        struct SourceTag: LeafTag {
            func render(_ ctx: LeafContext) throws -> LeafData {
                .string(ctx.request?.url.path ?? "application")
            }
        }

        try await withApp { app in
            app.views.use(.leaf)
            app.leaf.configuration.rootDirectory = "/"
            app.leaf.cache.isEnabled = false
            app.leaf.tags["source"] = SourceTag()
            app.leaf.sources = .singleSource(test)

            app.get("test-file") { req in
                try await req.view.render("foo", [
                    "name": "vapor"
                ])
            }
            app.get("test-file-with-application-renderer") { req in
                try await req.application.leaf.renderer.render("foo", [
                    "name": "World"
                ])
            }

            try await app.test(.GET, "test-file") { res async in
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .html)
                #expect(res.body.string == "Hello vapor @ /test-file")
            }

            try await app.test(.GET, "test-file-with-application-renderer") { res async in
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .html)
                #expect(res.body.string == "Hello World @ application")
            }
        }
    }

    @Test("context userInfo")
    func contextUserInfo() async throws {
        var test = TestFiles()
        test.files["/foo.leaf"] = """
            Hello #custom()! @ #source() app nil? #application()
            """

        struct CustomTag: LeafTag {
            func render(_ ctx: LeafContext) throws -> LeafData {
                .string(ctx.userInfo["info"] as? String ?? "")
            }
        }

        struct SourceTag: LeafTag {
            func render(_ ctx: LeafContext) throws -> LeafData {
                .string(ctx.request?.url.path ?? "application")
            }
        }
        
        struct ApplicationTag: LeafTag {
            func render(_ ctx: LeafContext) throws -> LeafData {
                .string(ctx.application != nil ? "non-nil app" : "nil app")
            }
        }

        try await withApp { app in
            app.views.use(.leaf)
            app.leaf.configuration.rootDirectory = "/"
            app.leaf.cache.isEnabled = false
            app.leaf.tags["custom"] = CustomTag()
            app.leaf.tags["source"] = SourceTag()
            app.leaf.tags["application"] = ApplicationTag()
            app.leaf.sources = .singleSource(test)
            app.leaf.userInfo["info"] = "World"

            app.get("test-file") { req in
                try await req.view.render("foo")
            }
            app.get("test-file-with-application-renderer") { req in
                try await req.application.leaf.renderer.render("foo")
            }

            try await app.test(.GET, "test-file") { res async in
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .html)
                #expect(res.body.string == "Hello World! @ /test-file app nil? non-nil app")
            }

            try await app.test(.GET, "test-file-with-application-renderer") { res async in
                #expect(res.status == .ok)
                #expect(res.headers.contentType == .html)
                #expect(res.body.string == "Hello World! @ application app nil? non-nil app")
            }
        }
    }

    @Test("LeafCache is disabled in development")
    func leafCacheDisabledInDevelopment() async throws {
        let app = try await Application.make(.development)

        app.views.use(.leaf)

        do {
            let renderer = try #require(app.view as? LeafRenderer)

            #expect(!renderer.cache.isEnabled)
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    @Test("LeafCache is enabled in production")
    func leafCacheEnabledInProduction() async throws {
        let app = try await Application.make(.production)

        app.views.use(.leaf)

        do {
            let renderer = try #require(app.view as? LeafRenderer)

            #expect(renderer.cache.isEnabled)
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    @Test("LeafRenderer with Encodable context")
    func leafRendererWithEncodableContext() async throws {
        var test = TestFiles()
        test.files["/foo.leaf"] = """
            Hello #(name)!
            """

        try await withApp { app in
            app.views.use(.leaf)
            app.leaf.sources = .singleSource(test)

            struct NotHTML: AsyncResponseEncodable {
                var data: ByteBuffer

                func encodeResponse(for request: Request) async throws -> Response {
                    .init(
                        headers: ["content-type": "application/not-html"],
                        body: .init(buffer: self.data)
                    )
                }
            }

            struct Foo: Encodable {
                var name: String
            }

            app.get("foo") { req in
                let data = try await req.application.leaf.renderer.render(path: "foo", context: Foo(name: "World")).get()

                return NotHTML(data: data)
            }

            try await app.test(.GET, "foo") { res async in
                #expect(res.status == .ok)
                #expect(res.headers.first(name: "content-type") == "application/not-html")
                #expect(res.body.string == "Hello World!")
            }
        }
    }

    @Test("no fatalError() when attempting to use array as context")
    func noFatalErrorWhenAttemptingToUseArrayAsContext() async throws {
        var test = TestFiles()
        test.files["/foo.leaf"] = """
            Hello #(name)!
            """

        try await withApp { app in
            app.views.use(.leaf)
            app.leaf.sources = .singleSource(test)

            struct MyModel: Content {
                let name: String
            }

            app.get("noCrash") { req -> View in
                let myModel1 = MyModel(name: "Alice")
                let myModel2 = MyModel(name: "Alice")
                let context = [myModel1, myModel2]
                return try await req.view.render("foo", context)
            }

            try await app.test(.GET, "noCrash") { res async in
                #expect(res.status == .internalServerError)
            }
        }
    }
    
    // Test for GH Issue #197
    @Test("no fatalError() when attempting to use array with nil")
    func noFatalErrorWhenAttemptingToUseArrayWithNil() async throws {
        var test = TestFiles()
        test.files["/foo.leaf"] = """
            #(value)
            """

        try await withApp { app in
            app.views.use(.leaf)
            app.leaf.sources = .singleSource(test)

            struct ArrayWithNils: Content {
                let value: [UUID?]
            }

            let id1 = UUID.init()
            let id2 = UUID.init()


            app.get("noCrash") { req -> View in
                let context = ArrayWithNils(value: [id1, nil, id2, nil])

                return try await req.view.render("foo", context)
            }

            try await app.test(.GET, "noCrash") { res async in
                // Expected result .ok
                #expect(res.status == .ok)

                // Rendered result should match to all non-nil values
                #expect(res.body.string == "[&quot;\(id1)&quot;, &quot;\(id2)&quot;]")
            }
        }
    }
}

/// Helper `LeafFiles` struct providing an in-memory thread-safe map of "file names" to "file data"
struct TestFiles: LeafSource {
    var files: [String: String]
    var lock: NIOLock

    init() {
        files = [:]
        lock = .init()
    }
    
    public func file(template: String, escape: Bool = false, on eventLoop: any EventLoop) -> EventLoopFuture<ByteBuffer> {
        var path = template

        if path.split(separator: "/").last?.split(separator: ".").count ?? 1 < 2,
           !path.hasSuffix(".leaf")
        {
            path += ".leaf"
        }
        if !path.starts(with: "/") {
            path = "/" + path
        }

        return self.lock.withLock {
            if let file = self.files[path] {
                var buffer = ByteBufferAllocator().buffer(capacity: file.count)
                buffer.writeString(file)
                return eventLoop.makeSucceededFuture(buffer)
            } else {
                return eventLoop.makeFailedFuture(LeafError(.noTemplateExists(template)))
            }
        }
    }
}

var templateFolder: String {
    URL(fileURLWithPath: #filePath, isDirectory: false)
        .deletingLastPathComponent()
        .appendingPathComponent("Views", isDirectory: true)
        .path
}

var projectFolder: String {
    URL(fileURLWithPath: #filePath, isDirectory: false) // .../leaf/Tests/LeafTests/LeafTests.swift
        .deletingLastPathComponent() // .../leaf/Tests/LeafTests
        .deletingLastPathComponent() // .../leaf/Tests
        .deletingLastPathComponent() // .../leaf
        .path
}
