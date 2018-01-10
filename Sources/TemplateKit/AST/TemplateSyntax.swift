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
    public var path: TemplateSyntax

    public init(path: TemplateSyntax) {
        self.path = path
    }
}

public final class TemplateConditional {
    public var condition: TemplateSyntax
    public var body: [TemplateSyntax]
    public var next: TemplateConditional?

    public init(
        condition: TemplateSyntax,
        body: [TemplateSyntax],
        next: TemplateConditional?
    ) {
        self.condition = condition
        self.body = body
        self.next = next
    }
}

extension TemplateConditional: CustomStringConvertible {
    public var description: String {
        return "\(condition) : \(next?.description ?? "n/a")"
    }
}

public struct TemplateIterator {
    public var key: TemplateSyntax
    public var data: TemplateSyntax
    public var body: [TemplateSyntax]

    public init(
        key: TemplateSyntax,
        data: TemplateSyntax,
        body: [TemplateSyntax]
    ) {
        self.key = key
        self.data = data
        self.body = body
    }
}

extension TemplateIterator: CustomStringConvertible {
    public var description: String {
        return "\(key) \(data)"
    }
}

public indirect enum TemplateSyntaxType {
    case raw(TemplateRaw)
    case tag(TemplateTag)
    case embed(TemplateEmbed)
    case conditional(TemplateConditional)
    case identifier(TemplateIdentifier)
    case constant(TemplateConstant)
    case iterator(TemplateIterator)
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
        case .conditional(let cond): return "Conditional: \(cond))"
        case .iterator(let it): return "Iterator: \(it)"
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
        case .iterator: return "iterator"
        }
    }
}
