//// TODO: => Core
//extension Byte {
////    public static let openParenthesis = "(".makeBytes().first!
////    public static let closedParenthesis = ")".makeBytes().first!
//
//    public static let openCurly = "{".makeBytes().first!
//    public static let closedCurly = "}".makeBytes().first!
//
//    public static let quotationMark = "\"".makeBytes().first!
//}

// FIXME: Can this be rm?
extension Sequence where Iterator.Element == Byte {
    public static var whitespace: Bytes {
        return [ .space, .newLine, .carriageReturn, .horizontalTab]
    }
}
