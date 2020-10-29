import Leaf
import XCTVapor
import NIOConcurrencyHelpers

class LeafTestClass: XCTestCase {
    var app: Application { _app! }
    var _app: Application? = nil
    
    override func setUp() {
        _app = Application(.testing)
        
        LeafConfiguration.__VERYUNSAFEReset()
        LeafEngine.entities = .leaf4Core
        LeafEngine.cache.dropAll()
        LeafEngine.rootDirectory = projectFolder
        LeafEngine.sources = .init()
        LeafRenderer.Option.grantUnsafeEntityAccess = true
    }
    
    override func tearDown() { app.shutdown() }
}


internal var projectFolder: String { "/\(#file.split(separator: "/").dropLast(3).joined(separator: "/"))/" }
internal var templateFolder: String { projectFolder + "Views/" }
