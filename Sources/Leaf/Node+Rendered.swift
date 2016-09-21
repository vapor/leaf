extension Node {
    func rendered() throws -> Bytes {
        switch self {
        case .array(_), .object(_), .null:
            return []
        case let .bool(bool):
            return bool.description.bytes
        case let .number(number):
            return number.description.bytes
        case let .string(str):
            return str.htmlEscaped().bytes
        case let .bytes(bytes):
            return bytes
        }
    }
}
