import Foundation

extension Byte {
    // <
    static let lessThan: Byte = 60

    // >
    static let greaterThan: Byte = 62
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
        return bytes
            .split(separator: .ampersand, omittingEmptySubsequences: false)
            .joined(separator: "&amp;".bytes)
            .split(separator: .quotationMark, omittingEmptySubsequences: false)
            .joined(separator: "&quot;".bytes)
            .split(separator: .apostrophe, omittingEmptySubsequences: false)
            .joined(separator: "&#39;".bytes)
            .split(separator: .lessThan, omittingEmptySubsequences: false)
            .joined(separator: "&lt;".bytes)
            .split(separator: .greaterThan, omittingEmptySubsequences: false)
            .joined(separator: "&gt;".bytes)
            .string
    }
}
