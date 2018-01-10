import Async
import Foundation

public final class Capitalize: TagRenderer {
    public init() {}
    public func render(tag parsed: TagContext) throws -> Future<TemplateData> {
        try parsed.requireParameterCount(1)
        let string = parsed.parameters[0].string?.capitalized ?? ""
        return Future(.string(string))
    }
}
