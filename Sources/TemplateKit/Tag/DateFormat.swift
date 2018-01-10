import Async
import Foundation

public final class DateFormat: TagRenderer {
    public init() {}
    public func render(tag parsed: TagContext) throws -> Future<TemplateData> {
        try parsed.requireParameterCount(2)

        let formatter = DateFormatter()
        let date = Date(timeIntervalSinceReferenceDate: parsed.parameters[0].double ?? 0)
        formatter.dateFormat = parsed.parameters[1].string ?? "yyyy-MM-dd HH:mm:ss"

        return Future(.string(formatter.string(from: date)))
    }
}
