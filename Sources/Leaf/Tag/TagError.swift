enum TagError: Error {
    case missingParameter(Int)
    case invalidParameterType(Int, Data?, expected: Any.Type)
    case missingBody
    case extraneousBody
    case custom(String)
}
