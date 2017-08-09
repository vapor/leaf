import Bits

public final class Comment: Tag {
    public init() {}
    public func render(parsed: ParsedTag, context: inout Data, renderer: Renderer) throws -> Data? {
        return .string("")
    }
}
