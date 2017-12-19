import XCTest
@testable import LeafTests

XCTMain([
    testCase(LeafTests.allTests),
    testCase(LeafEncoderTests.allTests),
])
