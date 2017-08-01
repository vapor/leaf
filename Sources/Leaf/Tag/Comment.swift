import Bits

public final class Comment: Tag {
    public init() {}

    public func render(
        parameters: [Data?],
        context: inout Data,
        indent: Int,
        body: [Syntax]?,
        renderer: Renderer
    ) throws -> Data? {
        return .string("")
    }
}
