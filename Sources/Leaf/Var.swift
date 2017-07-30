import Bits

public final class Var: Tag {
    public init() {}

    public func render(
        parameters: [Data],
        context: inout Data,
        body: Bytes?,
        renderer: Renderer
    ) throws -> Bytes {
        guard case .dictionary(var dict) = context else {
            throw "context must be a dictionary to set it"
        }

        switch parameters.count {
        case 1:
            guard let body = body else {
                throw "body required for one parameter var"
            }

            guard let key = parameters[0].string else {
                throw "could not convert var param to a string"
            }

            dict[key] = .string(body.makeString())
        case 2:
            guard let key = parameters[0].string else {
                throw "could not convert first var param to a string"
            }

            dict[key] = parameters[1]
        default:
            throw "one or two params required"
        }

        context = .dictionary(dict)
        return []
    }
}

