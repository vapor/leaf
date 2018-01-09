/// Errors that can be thrown by the Leaf serializer.
public struct TemplateSerializerError: Error {
    public let source: TemplateSource
    public let reason: String

    static func unexpectedSyntax(_ syntax: TemplateSyntax) -> TemplateSerializerError {
        return .init(source: syntax.source, reason: "Unexpected \(syntax.type.name).")
    }

    static func unexpectedTagData(name: String, source: TemplateSource) -> TemplateSerializerError {
        return .init(source: source, reason: "Could not convert data returned by tag \(name) to Data.")
    }

    static func unknownTag(name: String, source: TemplateSource) -> TemplateSerializerError {
        return .init(source: source, reason: "Unknown tag `\(name)`.")
    }

    static func invalidNumber(_ data: TemplateData, source: TemplateSource) -> TemplateSerializerError {
        return .init(source: source, reason: "`\(data)` is not a valid number.")
    }
}

