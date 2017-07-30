import Bits

public final class Embed: Tag {
    public init() {}

    public func render(
        parameters: [Data],
        context: inout Data,
        body: Bytes?,
        renderer: Renderer
    ) throws -> Bytes {
        guard parameters.count == 1 else {
            throw "invalid param count for embed"
        }

        guard let name = parameters[0].string else {
            throw "could not convert embed param to file name string"
        }

        return try renderer.render(path: name, context: context)
    }
}


