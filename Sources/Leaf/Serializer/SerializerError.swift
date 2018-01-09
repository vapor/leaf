/// Errors that can be thrown by the Leaf serializer.
public struct LeafSerializerError: Error {
    public let source: TemplateSource
    public let reason: String

    static func unexpectedSyntax(_ syntax: TemplateSyntax) -> LeafSerializerError {
        return .init(source: syntax.source, reason: "Unexpected \(syntax.type.name).")
    }

    static func unexpectedTagData(name: String, source: TemplateSource) -> LeafSerializerError {
        return .init(source: source, reason: "Could not convert data returned by tag \(name) to Data.")
    }

    static func unknownTag(name: String, source: TemplateSource) -> LeafSerializerError {
        return .init(source: source, reason: "Unknown tag `\(name)`.")
    }

    static func invalidNumber(_ data: LeafData?, source: TemplateSource) -> LeafSerializerError {
        let data: LeafData = data ?? .null
        return .init(source: source, reason: "`\(data)` is not a valid number.")
    }
}
