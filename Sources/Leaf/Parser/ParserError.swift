public enum ParserError: Error {
    case expectationFailed(expected: String, got: String)
    static let unexpectedEOF: ParserError = .expectationFailed(expected: "bytes", got: "EOF")
}
