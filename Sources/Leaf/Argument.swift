/**
    Concrete representation of a parameter
*/
public enum Argument {
    case variable(key: String, value: Node?)
    case constant(value: String)
}
