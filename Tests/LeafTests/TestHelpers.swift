import Leaf
import XCTLeafKit
import XCTVapor
import NIOConcurrencyHelpers

class LeafTestClass: LeafKitTestCase {
    var app: Application { _app! }
    var _app: Application? = nil
    
    override func setUp() {
        _app = Application(.testing)
        LeafEngine.cache.dropAll()
        LeafEngine.rootDirectory = projectFolder
        LeafEngine.sources = .init()
    }
    
    override func tearDown() { app.shutdown() }
}


var projectFolder: String { "/\(#file.split(separator: "/").dropLast(3).joined(separator: "/"))/" }
var templateFolder: String { projectFolder + "Views/" }
