extension Sequence where Iterator.Element == Byte {
    public static var whitespace: Bytes {
        return [ .space, .newLine, .carriageReturn, .horizontalTab]
    }
}
