import Bits

public protocol Tag {
    func render(
        parameters: [Data],
        context: inout Data,
        body: Bytes?,
        renderer: Renderer
    ) throws -> Bytes
}

// MARK: Convenience

extension Tag {
    public func requireParameter(_ n: Int, from parameters: [Data]) throws -> Data {
        guard parameters.count > n else {
            throw TagError.missingParameter(n)
        }
        
        return parameters[n]
    }

    public func requireBody(_ body: Bytes?) throws -> Bytes {
        guard let body = body  else {
            throw TagError.missingBody
        }

        return body
    }
}

// MARK: Global

public var defaultTags: [String: Tag] {
    return [
        "": Print(),
        "if": If(),
        "var": Var(),
        "embed": Embed()
    ]
}

