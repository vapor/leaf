import Bits

public final class Print: Tag {
    public init() { }

    public func render(parsed: ParsedTag, context: inout Data, renderer: Renderer) throws -> Data? {
        try parsed.requireNoBody()
        try parsed.requireParameterCount(1)
        let string = parsed.parameters[0].string ?? ""
        return .string(string.htmlEscaped())
    }
}

