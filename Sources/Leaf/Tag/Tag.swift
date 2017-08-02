import Bits

public protocol Tag {
    func render(
        parameters: [Data],
        context: inout Data,
        body: [Syntax]?,
        renderer: Renderer
    ) throws -> Data?
}

// MARK: Convenience

extension Tag {
    public func requireArrayParameter(_ n: Int, from parameters: [Data]) throws -> [Data] {
        let param = try requireParameter(n, from: parameters)
        guard let array = param.array else {
            throw TagError.invalidParameterType(n, param, expected: [Data].self)
        }
        return array
    }

    public func requireStringParameter(_ n: Int, from parameters: [Data]) throws -> String {
        let param = try requireParameter(n, from: parameters)
        guard let string = param.string else {
            throw TagError.invalidParameterType(n, param, expected: String.self)
        }
        return string
    }

    public func requireParameter(_ n: Int, from parameters: [Data]) throws -> Data {
        guard parameters.count > n else {
            throw TagError.missingParameter(n)
        }
        
        return parameters[n]
    }

    public func requireBody(_ body: [Syntax]?) throws -> [Syntax] {
        guard let body = body  else {
            throw TagError.missingBody
        }

        return body
    }

    public func requireNoBody(_ body: [Syntax]?) throws {
        guard body == nil else {
            throw TagError.extraneousBody
        }
    }
}

// MARK: Global

public var defaultTags: [String: Tag] {
    return [
        "": Print(),
        "ifElse": IfElse(),
        "var": Var(),
        "embed": Embed(),
        "loop": Loop(),
        "comment": Comment()
    ]
}

