import Async
import Dispatch
import Foundation

/// Serializes parsed AST, using context, into view bytes.
public final class TemplateSerializer {
    /// The serializer's parent renderer.
    public let renderer: TemplateRenderer

    /// The current context.
    public let context: TemplateContext

    /// The serializer's event loop.
    public let eventLoop: EventLoop

    /// Creates a new TemplateSerializer
    public init(renderer: TemplateRenderer, context: TemplateContext, on worker: Worker) {
        self.renderer = renderer
        self.context = context
        self.eventLoop = worker.eventLoop
    }

    /// Serializes the AST into Bytes.
    public func serialize(ast: [TemplateSyntax]) -> Future<View> {
        return Future {
            return try ast.map { syntax -> Future<Data> in
                return try self.render(syntax: syntax).map(to: Data.self) { context in
                    guard let data = context.data else {
                        throw TemplateSerializerError.unexpectedSyntax(syntax)
                    }

                    return data
                }
            }.map(to: View.self) { parts in
                let data = Data(parts.joined())
                return View(data: data)
            }
        }
    }

    // MARK: Private

    // Renders a `TemplateTag` to future `TemplateData`.
    private func render(tag: TemplateTag, source: TemplateSource) throws -> Future<TemplateData> {
        guard let tagRenderer = self.renderer.tags[tag.name] else {
            throw TemplateSerializerError.unknownTag(name: tag.name, source: source)
        }

        return try tag.parameters.map { parameter in
            return try self.render(syntax: parameter)
        }.flatMap(to: TemplateData.self) { inputs in
            let tagContext = TagContext(
                name: tag.name,
                parameters: inputs,
                body: tag.body,
                source: source,
                context: self.context,
                serializer: self,
                on: self.eventLoop
            )

            return try tagRenderer.render(tag: tagContext)
        }
    }

    // Renders a `TemplateConstant` to future `TemplateData`.
    private func render(constant: TemplateConstant, source: TemplateSource) -> Future<TemplateData> {
        switch constant {
        case .bool(let bool):
            return Future(.bool(bool))
        case .double(let double):
            return Future(.double(double))
        case .int(let int):
            return Future(.int(int))
        case .string(let ast):
            return serialize(ast: ast).map(to: TemplateData.self) { view in
                return .data(view.data)
            }
        }
    }

    // Renders an infix `TemplateExpression` to future `TemplateData`.
    private func render(infix: ExpressionInfixOperator, left: TemplateSyntax, right: TemplateSyntax, source: TemplateSource) throws -> Future<TemplateData> {
        return try map(to: TemplateData.self, render(syntax: left), render(syntax: right)) { left, right in
            switch infix {
            case .equal: return .bool(left == right)
            case .notEqual: return .bool(left != right)
            case .and: return .bool(left.bool != false && right.bool != false)
            case .or: return .bool(left.bool != false || right.bool != false)
            default:
                guard let leftDouble = left.double, let rightDouble = right.double else {
                    return .bool(false)
                }
                switch infix {
                case .add: return .double(leftDouble + rightDouble)
                case .subtract: return .double(leftDouble - rightDouble)
                case .multiply: return .double(leftDouble * rightDouble)
                case .divide: return .double(leftDouble / rightDouble)
                case .greaterThan: return .bool(leftDouble > rightDouble)
                case .lessThan: return .bool(leftDouble < rightDouble)
                default: fatalError("Unsupported operator: \(infix) at \(source)")
                }
            }
        }
    }

    // Renders an prefix `TemplateExpression` to future `TemplateData`.
    private func render(prefix: ExpressionPrefixOperator, right: TemplateSyntax, source: TemplateSource) throws -> Future<TemplateData> {
        return try render(syntax: right).map(to: TemplateData.self) { right in
            switch prefix {
            case .not: return .bool(right.bool.flatMap { !$0 } ?? false)
            }
        }
    }

    // Renders `TemplateConditional` to future `TemplateData`.
    private func render(conditional: TemplateConditional, source: TemplateSource) throws -> Future<TemplateData> {
        fatalError()
    }

    // Renders `TemplateEmbed` to future `TemplateData`.
    private func render(embed: TemplateEmbed, source: TemplateSource) throws -> Future<TemplateData> {
        fatalError()
    }

    // Renders `TemplateSyntax` to future `TemplateData`.
    private func render(syntax: TemplateSyntax) throws -> Future<TemplateData> {
        switch syntax.type {
        case .constant(let constant): return render(constant: constant, source: syntax.source)
        case .expression(let expr):
            switch expr {
            case .infix(let op, let left, let right): return try render(infix: op, left: left, right: right, source: syntax.source)
            case .prefix(let op, let right): return try render(prefix: op, right: right, source: syntax.source)
            case .postfix: fatalError("Unsupported expression: \(expr) at \(syntax.source)")
            }
        case .identifier(let id): return context.fetch(at: id.path)
        case .tag(let tag): return try render(tag: tag, source: syntax.source)
        case .raw(let raw): return Future(.data(raw.data))
        case .conditional(let cond): return try render(conditional: cond, source: syntax.source)
        case .embed(let embed): return try render(embed: embed, source: syntax.source)
        }
    }
}
