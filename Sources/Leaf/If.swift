import Bits

public final class If: Tag {
    public init() {}

    public func render(
        parameters: [Data],
        context: inout Data,
        body: Bytes?,
        renderer: Renderer
    ) throws -> Bytes {
        guard parameters.count == 1 else {
            throw "only one parameter allowed"
        }

        guard let body = body else {
            throw "body required for if"
        }
        
        if parameters[0].bool != false {
            return body
        } else {
            return []
        }
    }
}
