import Bits

extension Byte {
    func makeString() -> String {
        return [self].makeString()
    }

    var isAllowedInIdentifier: Bool {
        return isAlphanumeric || self == .hyphen || self == .underscore || self == .colon || self == .period
    }

    var isAllowedInTagName: Bool {
        return isAlphanumeric || self == .hyphen || self == .underscore || self == .colon || self == .forwardSlash || self == .asterisk
    }
}

func ~=(pattern: Byte, value: Byte?) -> Bool {
    return pattern == value
}
