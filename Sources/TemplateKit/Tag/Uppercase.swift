import Async

public final class Uppercase: TagRenderer {
    public init() {}
    public func render(tag parsed: TagContext) throws -> Future<TemplateData> {
        try parsed.requireParameterCount(1)
        let string = parsed.parameters[0].string?.uppercased() ?? ""
        return Future(.string(string))
    }
}
