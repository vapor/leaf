import Core

extension Byte {
    public static let openParenthesis = "(".bytes.first!
    public static let closedParenthesis = ")".bytes.first!

    public static let openCurly = "{".bytes.first!
    public static let closedCurly = "}".bytes.first!

    public static let quotationMark = "\"".bytes.first!
}

extension Byte {
    public var isLeafToken: Bool {
        return self == TOKEN
    }
}

extension Sequence where Iterator.Element == Byte {
    public static var whitespace: Bytes {
        return [ .space, .newLine, .carriageReturn, .horizontalTab]
    }
}
