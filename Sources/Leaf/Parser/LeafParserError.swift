/// Errors that can be thrown by the Leaf parser.
public struct LeafParserError: Error {
    public let source: TemplateSource
    public let reason: String

    static func expectationFailed(expected: String, got: String, source: TemplateSource) -> LeafParserError {
        return .init(source: source, reason: "Expected `\(expected)` got `\(got)`")
    }

    static func unexpectedEOF(source: TemplateSource) -> LeafParserError {
        return .expectationFailed(expected: "byte", got: "EOF", source: source)
    }
}
