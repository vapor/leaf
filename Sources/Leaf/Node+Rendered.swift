extension Node {
    func rendered() throws -> Bytes {
        switch self {
        case .array(_), .object(_), .null:
            return []
        case let .bool(bool):
            return bool.description.makeBytes()
        case let .number(number):
            return number.description.makeBytes()
        case let .string(str):
            // defaults to escaping, use #raw(var) to unescape. 
            return str.htmlEscaped().makeBytes()
        case let .bytes(bytes):
            return bytes
        case let .date(date):
            return Date.outgoingDateFormatter.string(from: date).makeBytes()
        }
    }
}
