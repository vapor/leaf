import Foundation

extension Data {
    static let `if` = Data("if".utf8)
    static let `for` = Data("for".utf8)
    
    static let lineComment = Data("//".utf8)
    static let blockComment = Data("/*".utf8)
    
    var isComment: Bool {
        return self == .lineComment || self == .blockComment
    }
}
