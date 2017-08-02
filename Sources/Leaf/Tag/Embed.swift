import Bits

public final class Embed: Tag {
    public init() {}
    public func render(parsed: ParsedTag, context: inout Data, renderer: Renderer) throws -> Data? {
        try parsed.requireParameterCount(1)
        let name = parsed.parameters[0].string ?? ""
        let bytes = try renderer.render(path: name, context: context)
        return .string(bytes.makeString())
    }
}


