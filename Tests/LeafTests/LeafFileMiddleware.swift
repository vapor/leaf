import Leaf
import XCTVapor
import NIOConcurrencyHelpers

class LeafFileMW: XCTestCase {
    override func setUp() {
        LeafConfiguration.__VERYUNSAFEReset()
        LeafEngine.entities = .leaf4Core
        LeafEngine.cache.dropAll()
        LeafEngine.rootDirectory = projectFolder
        LeafEngine.sources = .init()
        LeafRenderer.Context.grantUnsafeEntityAccess = true
        LeafRenderer.Context.missingVariableThrows = true
    }
    
    func testFileMiddleware() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        if let lfm = LeafFileMiddleware(publicDirectory: dir) {
            app.middleware.use(lfm)
            
            try app.testable().test(.GET, "/Leaf.leaf") {
                XCTAssertEqual($0.body.string, "Leaf\n") }
            
            try app.testable().test(.GET, "/LeafAs.html") {
                XCTAssertEqual($0.body.string, "Leaf\n") }
            
            try app.testable().test(.GET, "/NoLeafAs.html") {
                XCTAssertEqual($0.body.string, "No Leaf Here\n") }
            
            XCTAssertTrue(LeafEngine.cache.count == 2)
        } else { XCTFail("Couldn't initialize middleware") }
    }
}


private var dir: String { "/" + #file.split(separator: "/").dropLast(2).joined(separator: "/") + "/PublicDirectory/" }
