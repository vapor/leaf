import Bits

public final class Print: Tag {
    public init() { }

    public func render(
        parameters: [Data],
        context: inout Data,
        body: [Syntax]?,
        renderer: Renderer
    ) throws -> Data? {
        try requireNoBody(body)
        let string = try requireStringParameter(0, from: parameters)
        return .string(string.htmlEscaped())
    }
}

