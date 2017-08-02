import Bits

public final class Var: Tag {
    public init() {}

    public func render(
        parameters: [Data?],
        context: inout Data,
        body: [Syntax]?,
        renderer: Renderer
    ) throws -> Data? {
        guard case .dictionary(var dict) = context else {
            throw TagError.custom("context must be a dictionary to set it")
        }

        switch parameters.count {
        case 1:
            let body = try requireBody(body)
            let key = try requireStringParameter(0, from: parameters)
            let rendered = try renderer.render(body, context: context)
            dict[key] = .string(rendered.makeString())
        case 2:
            let key = try requireStringParameter(0, from: parameters)
            dict[key] = parameters[1]
        default:
            throw TagError.custom("1 or 2 params required")
        }

        context = .dictionary(dict)
        return .string("")
    }
}

