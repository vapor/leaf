import Dispatch

public struct ParsedTag {
    public let name: String
    public let parameters: [Context]
    public let body: [Syntax]?
    public let source: Source

    init(
        name: String,
        parameters: [Context],
        body: [Syntax]?,
        source: Source
    ) {
        self.name = name
        self.parameters = parameters
        self.body = body
        self.source = source
    }
}


extension ParsedTag {
    public func error(reason: String) -> TagError {
        return TagError(
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

    public func requireBody() throws -> [Syntax] {
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
