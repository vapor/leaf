import Async

public final class Lowercase: TagRenderer {
    public init() {}
    public func render(tag parsed: TagContext) throws -> Future<TemplateData> {
        try parsed.requireParameterCount(1)
        let string = parsed.parameters[0].string?.lowercased() ?? ""
        return Future(.string(string))
    }
}
