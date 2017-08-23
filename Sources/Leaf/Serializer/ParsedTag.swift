import Dispatch

public struct ParsedTag {
    public let name: String
    public let parameters: [Context]
    public let body: [Syntax]?
    public let source: Source
    public let queue: DispatchQueue

    init(
        name: String,
        parameters: [Context],
        body: [Syntax]?,
        source: Source,
        on queue: DispatchQueue
    ) {
        self.name = name
        self.parameters = parameters
        self.body = body
        self.source = source
        self.queue = queue
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
