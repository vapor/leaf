import Foundation

/// Serializes parsed Leaf ASTs into view bytes.
public final class Serializer {
    let ast: [Syntax]
    var context: Context
    let renderer: Renderer

    /// Creates a new Serializer.
    public init(ast: [Syntax], renderer: Renderer,  context: Context) {
        self.ast = ast
        self.context = context
        self.renderer = renderer
    }

    /// Serializes the AST into Bytes.
    func serialize() throws -> Data {
        var serialized = DispatchData.empty

        for syntax in ast {
            switch syntax.kind {
            case .raw(let data):
                serialized.append(data)
            case .tag(let name, let parameters, let body, let chained):
                if let data = try renderTag(name: name, parameters: parameters, body: body, chained: chained, source: syntax.source) {
                    guard let string = data.string else {
                        throw SerializerError.unexpectedSyntax(syntax)
                    }
                    guard let data = string.data(using: .utf8) else {
                        throw "could not convert string to data"
                    }
                    serialized.append(data.dispatchData)
                }
            default:
                throw SerializerError.unexpectedSyntax(syntax)
            }
        }

        return Data(serialized)
    }

    // MARK: private

    // renders a tag using the supplied context
    private func renderTag(name: String, parameters: [Syntax], body: [Syntax]?, chained: Syntax?, source: Source) throws -> Context? {
        guard let tag = renderer.tags[name] else {
            throw SerializerError.unknownTag(name: name, source: source)
        }

        var inputs: [Context] = []

        for parameter in parameters {
            let input = try resolveSyntax(parameter)
            inputs.append(input ?? .null)
        }

        let parsed = ParsedTag(name: name, parameters: inputs, body: body, source: source)
        if let data = try tag.render(
            parsed: parsed,
            context: &context,
            renderer: renderer
        ) {
            return data
        } else if let chained = chained {
            switch chained.kind {
            case .tag(let name, let params, let body, let c):
                return try renderTag(name: name, parameters: params, body: body, chained: c, source: chained.source)
            default:
                throw SerializerError.unexpectedSyntax(chained)
            }
        } else {
            return nil
        }


    }

    // resolves a constant to data
    private func resolveConstant(_ const: Constant) throws -> Context {
        switch const {
        case .bool(let bool):
            return .bool(bool)
        case .double(let double):
            return .double(double)
        case .int(let int):
            return .int(int)
        case .string(let ast):
            let serializer = Serializer(ast: ast, renderer: renderer, context: context)
            let bytes = try serializer.serialize()
            guard let string = String(data: bytes, encoding: .utf8) else {
                throw "could not parse string"
            }
            return .string(string)
        }
    }

    // resolves an expression to data
    private func resolveExpression(_ op: Operator, left: Syntax, right: Syntax) throws -> Context {
        let leftData = try resolveSyntax(left)
        let rightData = try resolveSyntax(right)

        switch op {
        case .equal:
            return .bool(leftData == rightData)
        case .notEqual:
            return .bool(leftData != rightData)
        case .and:
            return .bool(leftData?.bool != false && rightData?.bool != false)
        case .or:
            return .bool(leftData?.bool != false || rightData?.bool != false)
        default:
            break
        }

        guard let leftDouble = leftData?.double else {
            throw SerializerError.invalidNumber(leftData, source: left.source)
        }

        guard let rightDouble = rightData?.double else {
            throw SerializerError.invalidNumber(rightData, source: right.source)
        }

        switch op {
        case .add:
            return .double(leftDouble + rightDouble)
        case .subtract:
            return .double(leftDouble - rightDouble)
        case .greaterThan:
            return .bool(leftDouble > rightDouble)
        case .lessThan:
            return .bool(leftDouble < rightDouble)
        case .multiply:
            return .double(leftDouble * rightDouble)
        case .divide:
            return .double(leftDouble / rightDouble)
        default:
            return .bool(false)
        }
    }

    // resolves syntax to data (or fails)
    private func resolveSyntax(_ syntax: Syntax) throws -> Context? {
        switch syntax.kind {
        case .constant(let constant):
            return try resolveConstant(constant)
        case .expression(let op, let left, let right):
            return try resolveExpression(op, left: left, right: right)
        case .identifier(let id):
            guard let data = try contextFetch(path: id) else {
                return .null
            }
            return data
        case .tag(let name, let parameters, let body, let chained):
            return try renderTag(name: name, parameters: parameters, body: body, chained: chained, source: syntax.source)
        case .not(let syntax):
            switch syntax.kind {
            case .identifier(let id):
                guard let data = try contextFetch(path: id) else {
                    return .bool(true)
                }

                if data.bool == true {
                    return .bool(false)
                } else {
                    return .bool(true)
                }
            case .constant(let c):
                let ret: Bool

                switch c {
                case .bool(let bool):
                    ret = !bool
                case .double(let double):
                    ret = double != 1
                case .int(let int):
                    ret = int != 1
                case .string(_):
                    throw SerializerError.unexpectedSyntax(syntax)
                }

                return .bool(ret)
            default:
                throw SerializerError.unexpectedSyntax(syntax)
            }
        default:
            throw SerializerError.unexpectedSyntax(syntax)
        }
    }

    // fetches data from the context
    private func contextFetch(path: [String]) throws -> Context? {
        var current = context

        for part in path {
            guard let sub = current.dictionary?[part] else {
                return nil
            }

            current = sub
        }

        return current
    }
}

