import Bits

public final class Var: Tag {
    public init() {}

    public func render(parsed: ParsedTag, context: inout Data, renderer: Renderer) throws -> Data? {
        guard case .dictionary(var dict) = context else {
            return nil
        }

        switch parsed.parameters.count {
        case 1:
            let body = try parsed.requireBody()
            let key = parsed.parameters[0].string ?? ""
            let serializer = Serializer(ast: body, renderer: renderer, context: context)
            let rendered = try serializer.serialize()
            dict[key] = .string(rendered.makeString())
        case 2:
            let key = parsed.parameters[0].string ?? ""
            dict[key] = parsed.parameters[1]
        default:
            try parsed.requireParameterCount(2)
        }

        context = .dictionary(dict)
        return .string("")
    }
}
