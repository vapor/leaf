import Bits

extension Byte {
    func makeString() -> String {
        return [self].makeString()
    }

    var isAllowedInIdentifier: Bool {
        return isAlphanumeric || self == .hyphen || self == .underscore || self == .colon || self == .period
    }
}

func ~=(pattern: Byte, value: Byte?) -> Bool {
    return pattern == value
}
