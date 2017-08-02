public struct TagError: Error {
    public let tag: String
    public let kind: TagErrorKind
}

public enum TagErrorKind {
    case invalidParameterCount(need: Int, have: Int)
    case missingBody
    case extraneousBody
}
