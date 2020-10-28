import Leaf
import XCTVapor
import NIOConcurrencyHelpers

class LeafTests: LeafTestClass {
    func testApplication() throws {
        app.views.use(.leaf)

        app.get("test-file") { $0.view.render("Views/test", ["foo": "bar"]) }

        try app.test(.GET, "test-file", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual($0.headers.contentType, .html)
            XCTAssertContains($0.body.string, "test: bar")
        })
    }
    
    func testSandboxing() throws {
        LeafEngine.sources = .singleSource(NIOLeafFiles(fileio: app.fileio,
                                                        limits: .default,
                                                        sandboxDirectory: projectFolder,
                                                        viewDirectory: templateFolder))
        
        app.views.use(.leaf)

        app.get("hello") { $0.view.render("hello") }
        app.get("allowed") { $0.view.render("../hello") }
        app.get("sandboxed") { $0.view.render("../../hello") }

        try app.test(.GET, "hello", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual($0.headers.contentType, .html)
            XCTAssertEqual($0.body.string, "Hello, world!\n")
        })
        
        try app.test(.GET, "allowed", afterResponse: {
            XCTAssertEqual($0.status, .internalServerError)
            XCTAssert($0.body.string.contains("No template found"))
        })
        
        try app.test(.GET, "sandboxed", afterResponse: {
            XCTAssertEqual($0.status, .internalServerError)
            XCTAssert($0.body.string.contains("Attempted to escape sandbox"))
        })
    }

    func testContextRequest() throws {
        struct RequestPath: LeafUnsafeEntity, EmptyParams, StringReturn {
            var unsafeObjects: UnsafeObjects? = nil
            
            func evaluate(_ params: LeafCallValues) -> LeafData {
                .string(self.req?.url.path)
            }
        }
        
        let test = LeafTestFiles()
        
        LeafEngine.rootDirectory = "/"
        LeafEngine.sources = .singleSource(test)
        LeafEngine.entities.use(RequestPath(), asFunction: "path")
                
        test.files["/foo.leaf"] = """
        Hello #(name ?? "Unknown user") @ #(path() ?? "Could not retrieve path")
        """
        
        app.views.use(.leaf)

        app.get("test-file") {
            $0.leaf.render(template: "foo",
                           context: ["name": "vapor"],
                           options: [.caching(.bypass)])
        }

        try app.test(.GET, "test-file", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual($0.headers.contentType, .html)
            XCTAssertEqual($0.body.string, "Hello vapor @ /test-file")
        })
    }
    
    func testContextUserInfo() throws {
        struct CustomTag: LeafUnsafeEntity, EmptyParams, StringReturn {
            var unsafeObjects: UnsafeObjects? = nil
        
            func evaluate(_ params: LeafCallValues) -> LeafData {
                .string(unsafeObjects?["info"] as? String) }
        }
        
        let test = LeafTestFiles()
        test.files["/foo.leaf"] = "Hello #custom()!"
        
        LeafEngine.rootDirectory = "/"
        LeafEngine.sources = .singleSource(test)
        
        LeafEngine.entities.use(CustomTag(), asFunction: "custom")
        
        app.views.use(.leaf)
        try app.leaf.context.register(object: "World", toScope: "info", type: .unsafe)
        
        app.get("test-file") {
            $0.leaf.render(template: "foo", context: ["name": "vapor"])
        }

        try app.test(.GET, "test-file", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual($0.headers.contentType, .html)
            XCTAssertEqual($0.body.string, "Hello World!")
        })
    }
    
    func testLiteralContext() throws {
        let test = LeafTestFiles()
        test.files["/template.leaf"] = """
        Debug: #($app.isRelease != true)
        URI: #($req.url)
        """
        
        var isReleaseRequired: Bool {
            try! LeafEngine.cache.info(for: .searchKey("template"),
                                                 on: app.leaf.eventLoop)
                .wait()!.requiredVars.contains("$app.isRelease")
        }
        
        LeafEngine.sources = .singleSource(test)
                
        app.views.use(.leaf)
        app.middleware.use(ExtensionMiddleware())
        
        try app.leaf.context.register(generators: app.customVars, toScope: "app")
        
        app.get("template") { $0.leaf.render(template: "template", options: [.caching(.update)]) }
        
        try app.test(.GET, "template")
        XCTAssertTrue(isReleaseRequired)
        
        try app.leaf.context.lockAsLiteral(in: "app", key: "isRelease")
        try app.test(.GET, "template", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual($0.headers.contentType, .html)
            XCTAssertEqual($0.body.string, """
            Debug: true
            URI: ["host": , "isSecure": , "path": "/template", "port": , "query": ]
            """)
        })
        XCTAssertTrue(!isReleaseRequired)
    }
}

extension Application {
    var customVars: [String: LeafDataGenerator] {
        ["isRelease": .immediate(environment.isRelease)]
    }
}

extension Request {
    var customVars: [String: LeafDataGenerator] {
        ["url": .lazy(["isSecure": LeafData.bool(self.url.scheme?.contains("https")),
                        "host": LeafData.string(self.url.host),
                        "port": LeafData.int(self.url.port),
                        "path": LeafData.string(self.url.path),
                        "query": LeafData.string(self.url.query)]),
        ]
    }
}

struct ExtensionMiddleware: Middleware {
    func respond(to request: Request,
                 chainingTo next: Responder) -> EventLoopFuture<Response> {
        do {
            try request.leaf.context.register(generators: request.customVars, toScope: "req")
            return next.respond(to: request)
        }
        catch { return request.eventLoop.makeFailedFuture(error) }
    }
}
