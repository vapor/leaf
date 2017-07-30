import Bits

public final class Print: Tag {
    public init() { }

    public func render(
        parameters: [Data],
        context: inout Data,
        body: Bytes?,
        renderer: Renderer
    ) throws -> Bytes {
        guard body == nil else {
            throw "print tag may not have a body"
        }

        guard parameters.count == 1 else {
            throw "only one parameter allowed!"
        }

        guard let data = parameters[0].string else {
            throw "could convert input to a string"
        }

        return data.htmlEscaped().makeBytes()
    }
}

