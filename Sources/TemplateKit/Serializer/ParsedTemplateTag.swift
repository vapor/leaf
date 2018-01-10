import Async
import Dispatch

/// Represents a tag that has been parsed.
public struct TagContext {
    /// Name used for this tag.
    public let name: String

    /// Resolved parameters to this tag.
    public let parameters: [TemplateData]

    /// Optional tag body
    public let body: [TemplateSyntax]?

    /// TemplateSource code location of this parsed tag
    public let source: TemplateSource

    /// Queue to complete futures on.
    public let eventLoop: Worker

    /// The template data context
    public let context: TemplateContext

    /// The serializer that created this context
    public let serializer: TemplateSerializer

    /// Creates a new parsed tag struct.
    init(
        name: String,
        parameters: [TemplateData],
        body: [TemplateSyntax]?,
        source: TemplateSource,
        context: TemplateContext,
        serializer: TemplateSerializer,
        on worker: Worker
    ) {
        self.name = name
        self.parameters = parameters
        self.body = body
        self.source = source
        self.context = context
        self.serializer = serializer
        self.eventLoop = worker.eventLoop
    }
}


extension TagContext {
    /// Create a general tag error.
    public func error(reason: String) -> TemplateTagError {
        return .init(
            tag: name,
            source: source,
            reason: reason
        )
    }

    public func requireParameterCount(_ n: Int) throws {
        guard parameters.count == n else {
            throw error(reason: "Invalid parameter count: \(parameters.count)/\(n)")
        }
    }

    public func requireBody() throws -> [TemplateSyntax] {
        guard let body = body else {
            throw error(reason: "Missing body")
        }

        return body
    }

    public func requireNoBody() throws {
        guard body == nil else {
            throw error(reason: "Extraneous body")
        }
    }
}

public struct TemplateTagError: Error {
    public let tag: String
    public let source: TemplateSource
    public let reason: String
}


