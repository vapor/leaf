import Foundation

public struct TemplateSyntax {
    public let type: TemplateSyntaxType
    public let source: TemplateSource

    public init(type: TemplateSyntaxType, source: TemplateSource) {
        self.type = type
        self.source = source
    }
}

public struct TemplateEmbed {
    var path: String
}

public struct TemplateConditional {
    var ifTag: TemplateTag
    var elseTag: TemplateTag?
}

public indirect enum TemplateSyntaxType {
    case raw(TemplateRaw)
    case tag(TemplateTag)
    case embed(TemplateEmbed)
    case conditional(TemplateConditional)
    case identifier(TemplateIdentifier)
    case constant(TemplateConstant)
    case expression(TemplateExpression)

}

extension TemplateSyntax: CustomStringConvertible {
    public var description: String {
        switch type {
        case .raw(let source):
            let string = String(data: source.data, encoding: .utf8) ?? "n/a"
            return "Raw: \(string)"
        case .tag(let tag): return "Tag: \(tag)"
        case .identifier(let name): return "Identifier: \(name.path)"
        case .expression(let expr): return "Expression: (\(expr))"
        case .constant(let const): return "Contstant: \(const)"
        case .embed(let embed): return "Embed: \(embed.path)"
        case .conditional(let cond): return "Conditional: \(cond.ifTag) : \(cond.elseTag?.description ?? "n/a")"
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
        case .embed: return "embed"
        case .conditional: return "conditional"
        }
    }
}
