public enum SerializerError: Error {
    case unexpectedSyntax(Syntax)
    case invalidNumber(Data?)
    case unknownTag(name: String)
}

