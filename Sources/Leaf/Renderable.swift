extension Node {
    func rendered() throws -> Bytes {
        switch self {
        case .array(_), .object(_), .null:
            // TODO: Should throw?
            return []
        case let .bool(bool):
            return bool.description.bytes
        case let .number(number):
            return number.description.bytes
        case let .string(str):
            return str.bytes
        case let .bytes(bytes):
            return bytes
        }
    }
}
