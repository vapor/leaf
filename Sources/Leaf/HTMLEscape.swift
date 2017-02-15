import Foundation

extension Byte {
    // <
    static let lessThan: Byte = 0x3C

    // >
    static let greaterThan: Byte = 0x3E
}

extension String {
    func htmlEscaped() -> String {
        /**
             ***** WARNING ******
             
             Temporary resolution to the following issue in swift on linux:
             https://github.com/vapor/leaf/issues/41
             
             See:
             https://bugs.swift.org/browse/SR-3448
             
             Replace when appropriate with:
             
             return replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
        */
        return makeBytes()
            .split(separator: .ampersand, omittingEmptySubsequences: false)
            .joined(separator: "&amp;".makeBytes())
            .split(separator: .quote, omittingEmptySubsequences: false)
            .joined(separator: "&quot;".makeBytes())
            .split(separator: .apostrophe, omittingEmptySubsequences: false)
            .joined(separator: "&#39;".makeBytes())
            .split(separator: .lessThan, omittingEmptySubsequences: false)
            .joined(separator: "&lt;".makeBytes())
            .split(separator: .greaterThan, omittingEmptySubsequences: false)
            .joined(separator: "&gt;".makeBytes())
            .string
    }
}
