import Foundation

public struct TemplateSyntax {
    public let type: TemplateSyntaxType
    public let source: TemplateSource

    public init(type: TemplateSyntaxType, source: TemplateSource) {
        self.type = type
        self.source = source
    }
}

public struct TemplateTag {
    public var name: String
    public var parameters: [TemplateSyntax]
    public var body: [TemplateSyntax]?

    public init(name: String, parameters: [TemplateSyntax], body: [TemplateSyntax]?) {
        self.name = name
        self.parameters = parameters
        self.body = body
    }
}

public struct TemplateIdentifier {
    public var path: [CodingKey]
    public init(path: [CodingKey]) {
        self.path = path
    }
}

public struct TemlateRaw {
    public var data: Data

    public init(data: Data) {
        self.data = data
    }
}

public indirect enum TemplateSyntaxType {
    case raw(TemlateRaw)
    case tag(TemplateTag)
    case identifier(TemplateIdentifier)
    case constant(TemplateConstant)
    case expression(TemplateExpression)

}

extension TemplateSyntax: CustomStringConvertible {
    public var description: String {
        switch type {
        case .raw(let source):
            let string = String(data: source.data, encoding: .utf8) ?? "n/a"
            return "Raw: `\(string)`"
        case .tag(let tag):
            let params = tag.parameters.map { $0.description }
            let hasBody = tag.body != nil ? true : false
            return "Tag: \(tag.name)(\(params.joined(separator: ", "))) Body: \(hasBody)"
        case .identifier(let name):
            return "`\(name.path)`"
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
