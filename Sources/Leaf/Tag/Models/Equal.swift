public final class Equal: BasicTag {
    public enum Error: LeafError {
        case expected2Arguments
    }

    public let name = "equal"

    public func run(arguments: [Argument]) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expected2Arguments }
        return nil
    }

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument],
        value: Node?
    ) -> Bool {
        let left = arguments.first?.value
        let right = arguments.last?.value
        // return `left == right` to catch both `nil` case which should return `true`
        guard let lhs = left, let rhs = right else { return left == right }

        switch lhs {
        case let .array(array):
            guard let rhs = rhs.nodeArray else { return false }
            return array == rhs
        case let .bool(bool):
            return bool == rhs.bool
        case let .bytes(bytes):
            guard case let .bytes(rhs) = rhs else { return false }
            return bytes == rhs
        case .null:
            return rhs.isNull
        case let .number(number):
            switch number {
            case let .double(double):
                return double == rhs.double
            case let .int(int):
                return int == rhs.int
            case let .uint(uint):
                return uint == rhs.uint
            }
        case let .object(ob):
            guard let rhs = rhs.nodeObject else { return false }
            return ob == rhs
        case let .string(string):
            return string == rhs.string
        }
    }
}
