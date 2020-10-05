import Leaf
import XCTVapor
import NIOConcurrencyHelpers

class LeafTests: XCTestCase {
    override func setUp() {
        LeafConfiguration.__VERYUNSAFEReset()
        LeafEngine.entities = .leaf4Core
        LeafEngine.cache.dropAll()
        LeafEngine.rootDirectory = projectFolder
        LeafEngine.sources = .init()
        LeafRenderer.Context.grantUnsafeEntityAccess = true
        LeafRenderer.Context.missingVariableThrows = false
    }
    
    func testApplication() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.views.use(.leaf)

        app.get("test-file") { $0.view.render("Views/test", ["foo": "bar"]) }

        try app.test(.GET, "test-file", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual($0.headers.contentType, .html)
            XCTAssertContains($0.body.string, "test: bar")
        })
    }
    
    func testSandboxing() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
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
            var externalObjects: ExternalObjects? = nil
            
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
        
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.views.use(.leaf)

        app.get("test-file") {
            $0.leaf.render(template: "foo",
                           context: ["name": "vapor"],
                           options: [.cacheBypass(true)])
        }

        try app.test(.GET, "test-file", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual($0.headers.contentType, .html)
            XCTAssertEqual($0.body.string, "Hello vapor @ /test-file")
        })
    }
    
    func testContextUserInfo() throws {
        struct CustomTag: LeafUnsafeEntity, EmptyParams, StringReturn {
            var externalObjects: ExternalObjects? = nil
        
            func evaluate(_ params: LeafCallValues) -> LeafData {
                .string(externalObjects?["info"] as? String) }
        }
        
        let test = LeafTestFiles()
        test.files["/foo.leaf"] = "Hello #custom()!"
        
        LeafEngine.rootDirectory = "/"
        LeafEngine.sources = .singleSource(test)
        
        LeafEngine.entities.use(CustomTag(), asFunction: "custom")
        
        
        let app = Application(.testing)
        defer { app.shutdown() }

        app.views.use(.leaf)
        try app.leaf.context.register(object: "World", as: "info", type: .unsafe)
        
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
        Debug: #(!$app.isRelease)
        URI: #($req.url)
        """
        
        LeafEngine.sources = .singleSource(test)
        
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.views.use(.leaf)

        app.get("template") { $0.view.render("template") }

        try app.test(.GET, "template", afterResponse: {
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual($0.headers.contentType, .html)
            XCTAssertEqual($0.body.string, """
            Debug: true
            URI: ["host": , "isSecure": , "path": "/template", "port": , "query": ]
            """)
        })
    }
}
