import Bits

extension Byte {
    func makeString() -> String {
        return [self].makeString()
    }

    var isAllowedInIdentifier: Bool {
        return isAlphanumeric || self == .semicolon || self == .underscore || self == .colon
    }
}

func ~=(pattern: Byte, value: Byte?) -> Bool {
    return pattern == value
}
