import Foundation
import XCTest
@testable import Leaf

class HTMLEscapeTests: XCTestCase {
    static let allTests = [
        ("testHTMLEscape", testHTMLEscape),
        ("testHTMLEscapeCRLFQuotes", testHTMLEscapeCRLFQuotes),
    ]

    func testHTMLEscape() throws {
        let input = "&\"'<>"
        let expected = "&amp;&quot;&#39;&lt;&gt;"
        
        XCTAssertEqual(input.htmlEscaped(), expected)
    }
    
    func testHTMLEscapeCRLFQuotes() throws {
        let input = "\r\n\""
        let expected = "\r\n&quot;"
        
        XCTAssertEqual(input.htmlEscaped(), expected)
    }
}
