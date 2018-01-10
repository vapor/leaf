import Debugging

/// An error converting types.
public struct TemplateError: Debuggable, Error, Traceable {
    public let identifier: String
    public let reason: String
    public var file: String
    public var function: String
    public var line: UInt
    public var column: UInt
    public var stackTrace: [String]

    internal init(
        identifier: String,
        reason: String,
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.identifier = identifier
        self.reason = reason
        self.file = file
        self.function = function
        self.line = line
        self.column = column
        self.stackTrace = TemplateError.makeStackTrace()
    }

    static func serialize(reason: String, source: TemplateSource) -> TemplateError {
        return TemplateError(
            identifier: "serialize",
            reason: reason,
            file: "template",
            function: "serialize",
            line: UInt(source.line),
            column: UInt(source.column)
        )
    }
}
