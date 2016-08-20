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
