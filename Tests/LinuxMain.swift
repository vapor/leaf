import XCTest
@testable import LeafTests

XCTMain([
     testCase(PerformanceTests.allTests),
     testCase(ContextTests.allTests),
     testCase(LinkTests.allTests),
     testCase(TagTemplateTests.allTests),
     testCase(NodeRenderTests.allTests),
     testCase(BufferTests.allTests),
     testCase(IncludeTests.allTests),
     testCase(RenderTests.allTests),
     testCase(ParameterTests.allTests),
     testCase(LoopTests.allTests),
     testCase(IfTests.allTests),
     testCase(VariableTests.allTests),
     testCase(UppercasedTests.allTests),
])
