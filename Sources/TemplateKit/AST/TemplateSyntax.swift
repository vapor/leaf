import Foundation

public struct TemplateSyntax {
    public let type: TemplateSyntaxType
    public let source: TemplateSource

    public init(type: TemplateSyntaxType, source: TemplateSource) {
        self.type = type
        self.source = source
    }
}

public indirect enum TemplateSyntaxType {
    case raw(Data)
    case tag(name: String, parameters: [TemplateSyntax], body: [TemplateSyntax]?, chained: TemplateSyntax?)
    case identifier(path: [String])
    case constant(TemplateConstant)
    case expression(TemplateExpression)

}

extension TemplateSyntax: CustomStringConvertible {
    public var description: String {
        switch type {
        case .raw(let source):
            let string = String(data: source, encoding: .utf8) ?? "n/a"
            return "Raw: `\(string)`"
        case .tag(let name, let params, let body, _):
            let params = params.map { $0.description }
            let hasBody = body != nil ? true : false
            return "Tag: \(name)(\(params.joined(separator: ", "))) Body: \(hasBody)"
        case .identifier(let name):
            return "`\(name)`"
        case .expression(let expr):
            return "Expr: (\(expr))"
        case .constant(let const):
            return "c:\(const)"
        }
    }
}

extension TemplateSyntaxType  {
    public var name: String {
        switch self {
        case .constant: return "constant"
        case .expression: return "expression"
        case .identifier: return "identifier"
        case .raw: return "raw"
        case .tag: return "tag"
        }
    }
}
