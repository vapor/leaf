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
        }
    }
}
