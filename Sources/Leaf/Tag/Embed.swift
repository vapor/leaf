import Bits

public final class Embed: Tag {
    public init() {}

    public func render(
        parameters: [Data],
        context: inout Data,
        body: [Syntax]?,
        renderer: Renderer
    ) throws -> Data? {
        let name = try requireStringParameter(0, from: parameters)
        let bytes = try renderer.render(path: name, context: context)
        return .string(bytes.makeString())
    }
}


