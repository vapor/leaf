import Async
import Foundation

public final class DateFormat: Leaf.LeafTag {
    public init() {}
    public func render(parsed: ParsedTag, context: LeafContext, renderer: LeafRenderer) throws -> Future<LeafData?> {
        try parsed.requireParameterCount(2)

        let formatter = DateFormatter()
        let date = Date(timeIntervalSinceReferenceDate: parsed.parameters[0].double ?? 0)
        formatter.dateFormat = parsed.parameters[1].string ?? "yyyy-MM-dd HH:mm:ss"

        return Future(.string(formatter.string(from: date)))
    }
}
