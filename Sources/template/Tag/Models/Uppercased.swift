public final class Uppercased: Tag {
    public let name = "uppercased"

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Any? {
        guard arguments.count == 1 else { throw "\(self) only accepts single arguments" }
        switch arguments[0] {
        case let .constant(value: value):
            return value.uppercased()
        case let .variable(key: _, value: value as String):
            return value.uppercased()
        case let .variable(key: _, value: value as Renderable):
            return try value.rendered().string.uppercased()
        case let .variable(key: _, value: value?):
            return "\(value)".uppercased()
        default:
            return nil
        }
    }
}
