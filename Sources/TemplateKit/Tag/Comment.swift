import Async

public final class Comment: TagRenderer {
    public init() {}
    public func render(tag parsed: TagContext) throws -> Future<TemplateData> {
        return Future(.string(""))
    }
}
