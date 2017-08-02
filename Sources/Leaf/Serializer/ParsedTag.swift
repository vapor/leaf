public struct ParsedTag {
    public let name: String
    public let parameters: [Data]
    public let body: [Syntax]?

    init(name: String, parameters: [Data], body: [Syntax]?) {
        self.name = name
        self.parameters = parameters
        self.body = body
    }
}


extension ParsedTag {
    public func requireParameterCount(_ n: Int) throws {
        guard parameters.count == n else {
            throw TagError(
                tag: name,
                kind: .invalidParameterCount(need: n, have: parameters.count)
            )
        }
    }

    public func requireBody() throws -> [Syntax] {
        guard let body = body else {
            throw TagError(
                tag: name,
                kind: .missingBody
            )
        }

        return body
    }

    public func requireNoBody() throws {
        guard body == nil else {
            throw TagError(
                tag: name,
                kind: .extraneousBody
            )
        }
    }
}
