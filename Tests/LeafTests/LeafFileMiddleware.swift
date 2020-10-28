import Leaf
import XCTVapor
import NIOConcurrencyHelpers

class LeafFileMW: LeafTestClass {
    func setupMiddleware() throws {
        let middleware = LeafFileMiddleware(publicDirectory: dir)
        if let lfm = middleware { app.middleware.use(lfm) }
        else { throw "Couldn't initialize middleware" }
        
        LeafFileMiddleware.defaultContext?.options = [.missingVariableThrows(false)]
        
        app.views.use(.leaf)
    }
    
    func testBasic() throws {
        try setupMiddleware()
        
        try app.testable().test(.GET, "/Leaf.leaf") {
            XCTAssertEqual($0.body.string, "Leaf\nNo Version Set\n") }
        
        try app.testable().test(.GET, "/LeafAs.html") {
            XCTAssertEqual($0.body.string, "Leaf\n") }
        
        try app.testable().test(.GET, "/NoLeafAs.html") {
            XCTAssertEqual($0.body.string, "No Leaf Here\n") }
        
        XCTAssertTrue(LeafEngine.cache.count == 2)
    }
    
    func testProhibit() throws {
        LeafFileMiddleware.directoryIndexing = .prohibit
        try setupMiddleware()
        
        try app.testable().test(.GET, "/") {
            XCTAssert($0.body.string.contains("Directory indexing disallowed")) }
    }
    
    func testIgnore() throws {
        LeafFileMiddleware.directoryIndexing = .ignore
        try setupMiddleware()
                
        try app.testable().test(.GET, "/") {
            XCTAssert($0.body.string.contains("Not Found")) }
    }
    
    func testRelative() throws {
        LeafFileMiddleware.directoryIndexing = .relative("Index.leaf")
        try setupMiddleware()
                
        try app.testable().test(.GET, "/") {
            XCTAssert($0.body.string.contains("Index.leaf")) }
    }
    
    func testAbsolute() throws {
        LeafFileMiddleware.directoryIndexing = .absolute(dir + "Index.leaf")
        try setupMiddleware()
                
        try app.testable().test(.GET, "/") {
            print($0.body.string)
            XCTAssert($0.body.string.contains("Index.leaf")) }
    }
    
    func testTypeContext() throws {
        try setupMiddleware()
        
        try LeafFileMiddleware.defaultContext?.setValue(at: "version", to: "1.0.0")
        
        try app.testable().test(.GET, "/Leaf.leaf") {
            XCTAssert($0.body.string.contains("1.0.0")) }
    }
}


private var dir: String { "/" + #file.split(separator: "/").dropLast(2).joined(separator: "/") + "/PublicDirectory/" }
