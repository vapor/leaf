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
    case constant(value: String)
}

public extension Argument {
    var value: Node? {
        switch self {
        case let .constant(value: value):
            return .string(value)
        case let .variable(path: _, value: value):
            return value
        }
    }
}
