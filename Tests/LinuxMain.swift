import XCTest
@testable import LeafTests

XCTMain([
     testCase(BufferTests.allTests),
     testCase(ContextTests.allTests),
     testCase(EmbedTests.allTests),
     testCase(EqualTests.allTests),
     testCase(FileLoadTests.allTests),
     testCase(IfTests.allTests),
     testCase(IndexTests.allTests),
     testCase(HTMLEscapeTests.allTests),
     testCase(LinkTests.allTests),
     testCase(LoopTests.allTests),
     testCase(NodeRenderTests.allTests),
     testCase(ParameterTests.allTests),
     testCase(PerformanceTests.allTests),
     testCase(RenderTests.allTests),
     testCase(TagTemplateTests.allTests),
     testCase(UppercasedTests.allTests),
     testCase(VariableTests.allTests),
     testCase(LayoutTests.allTests),
     testCase(RawTests.allTests),
     testCase(BodyWhitespaceTests.allTests)
])
