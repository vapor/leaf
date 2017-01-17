import Foundation

extension String {
    func htmlEscaped() -> String {
        return replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;", options: [.regularExpression])
            .replacingOccurrences(of: "'", with: "&#39;", options: [.regularExpression])
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
