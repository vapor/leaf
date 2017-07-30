import Bits

public protocol Tag {
    func render(
        parameters: [Data],
        context: inout Data,
        body: Bytes?,
        renderer: Renderer
    ) throws -> Bytes
}

public var defaultTags: [String: Tag] {
    return [
        "": Print(),
        "if": If(),
        "var": Var(),
        "embed": Embed()
    ]
}
