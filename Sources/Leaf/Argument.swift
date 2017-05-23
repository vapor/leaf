/**
    Concrete representation of a parameter
*/
public enum Argument {
    /**
        - parameter path: path declared for variable
        - parameter value: found value in given scope
    */
    case variable(path: [String], value: Node?)

    /**
        - parameter value: the value for a given constant. Declared w/ `""`
    */
    case constant(Leaf)

    case expression(arguments: [String])
}



extension Argument {
    public func value(with stem: Stem, in context: Context) -> Node? {
        switch self {
        case let .constant(leaf):
            guard let rendered = try? stem.render(leaf, with: context) else { return nil }
            let string = rendered.makeString()
            return .string(string)
        case let .variable(path: _, value: value):
            return value
        case let .expression(arguments: args):
            return stem.expression(matching: args)?.evaluate(args, with: stem, in: context)
        }
    }
}

public struct ArgumentList {
    public let list: [Argument]
    public let stem: Stem
    public let context: Context

    public var isEmpty: Bool { return list.isEmpty }
    public var count: Int { return list.count }

    public var first: Node? {
        return self[0]
    }

    public var last: Node? {
        let last = list.count - 1
        return self[last]
    }

    public init(list: [Argument], stem: Stem, context: Context) {
        self.list = list
        self.stem = stem
        self.context = context
    }

    public subscript(idx: Int) -> Node? {
        guard idx < list.count else { return nil }
        return list[idx].value(with: stem, in: context)
    }
}

final class ExpressionParser {
    let components: [Any]

    init(_ bytes: Bytes) {
        components = bytes.split(separator: .space, omittingEmptySubsequences: true)
    }
}

extension Sequence where Iterator.Element == Byte {
    var isVariable: Bool { return false }
    var isConstant: Bool { return false }
    var isOperation: Bool { return false }
}

public let defaultExpressions: [Expression] = [
    EqualsExpression(),
]

public protocol Expression {
    func matches(_ arguments: [String]) -> Bool
    func evaluate(_ arguments: [String], with stem: Stem, in context: Context) -> Node?
}

public final class EqualsExpression: Expression {
    public func matches(_ arguments: [String]) -> Bool {
        return arguments.count == 3
        && arguments[1] == "=="
    }

    public func evaluate(_ arguments: [String], with stem: Stem, in context: Context) -> Node? {
        let lhs = value(for: arguments[0], in: context)
        let rhs = value(for: arguments[2], in: context)
        return fuzzyEquals(lhs, rhs).makeNode(in: nil)
    }
}

extension Expression {
    public func value(for arg: String, in context: Context) -> Node? {
        if arg.hasPrefix("\"") && arg.hasSuffix("\"") {
            return arg.makeBytes().dropFirst().dropLast().makeString().makeNode(in: nil)
        } else {
            return context.get(path: arg.components(separatedBy: "."))
        }
    }
}
