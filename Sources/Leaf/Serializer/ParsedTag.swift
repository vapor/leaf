public struct ParsedTag {
    public let name: String
    public let parameters: [Data]
    public let body: [Syntax]?
    public let source: Source

    init(name: String, parameters: [Data], body: [Syntax]?, source: Source) {
        self.name = name
        self.parameters = parameters
        self.body = body
        self.source = source
    }
}


extension ParsedTag {
    public func requireParameterCount(_ n: Int) throws {
        guard parameters.count == n else {
            throw TagError(
                tag: name,
                source: source,
                reason: "Invalid parameter count: \(parameters.count)/\(n)."
            )
        }
    }

    public func requireBody() throws -> [Syntax] {
        guard let body = body else {
            throw TagError(
                tag: name,
                source: source,
                reason: "Missing body."
            )
        }

        return body
    }

    public func requireNoBody() throws {
        guard body == nil else {
            throw TagError(
                tag: name,
                source: source,
                reason: "Extraneous body."
            )
        }
    }
}
