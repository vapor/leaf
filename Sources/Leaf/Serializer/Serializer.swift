import Bits

final class Serializer {
    let ast: [Syntax]
    var context: Data
    let renderer: Renderer

    init(ast: [Syntax], renderer: Renderer,  context: Data) {
        self.ast = ast
        self.context = context
        self.renderer = renderer
    }

    func serialize() throws -> Bytes {
        var serialized: Bytes = []

        for syntax in ast {
            do {
                switch syntax.kind {
                case .raw(let data):
                    serialized += data
                case .tag(let name, let parameters, let body, let chained):
                    let bytes: Bytes
                    if let data = try renderTag(name: name, parameters: parameters, body: body, chained: chained) {
                        guard let string = data.string else {
                            throw SerializerError.unexpectedSyntax(syntax)
                        }
                        bytes = string.makeBytes()
                    }else {
                        bytes = []
                    }
                    serialized += bytes
                default:
                    throw SerializerError.unexpectedSyntax(syntax)
                }
            } catch {
                throw RenderError(
                    source: syntax.source,
                    error: error
                )
            }
        }

        return serialized
    }

    private func renderTag(name: String, parameters: [Syntax], body: [Syntax]?, chained: Syntax?) throws -> Data? {
        guard let tag = renderer.tags[name] else {
            throw SerializerError.unknownTag(name: name)
        }

        var inputs: [Data] = []

        for parameter in parameters {
            let input = try resolveSyntax(parameter)
            inputs.append(input ?? .null)
        }

        let parsed = ParsedTag(name: name, parameters: inputs, body: body)
        if let data = try tag.render(
            parsed: parsed,
            context: &context,
            renderer: renderer
        ) {
            return data
        } else if let chained = chained {
            switch chained.kind {
            case .tag(let name, let params, let body, let chained):
                return try renderTag(name: name, parameters: params, body: body, chained: chained)
            default:
                throw SerializerError.unexpectedSyntax(chained)
            }
        } else {
            return nil
        }


    }

    private func resolveConstant(_ const: Constant) throws -> Data {
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
            return .string(bytes.makeString())
        }
    }

    private func resolveExpression(_ op: Operator, left: Syntax, right: Syntax) throws -> Data {
        let left = try resolveSyntax(left)
        let right = try resolveSyntax(right)

        switch op {
        case .equal:
            return .bool(left?.string == right?.string)
        case .notEqual:
            return .bool(left?.string != right?.string)
        default:
            break
        }

        guard let leftDouble = left?.double else {
            throw SerializerError.invalidNumber(left)
        }

        guard let rightDouble = right?.double else {
            throw SerializerError.invalidNumber(right)
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

    private func resolveSyntax(_ syntax: Syntax) throws -> Data? {
        switch syntax.kind {
        case .constant(let constant):
            return try resolveConstant(constant)
        case .expression(let op, let left, let right):
            return try resolveExpression(op, left: left, right: right)
        case .identifier(let id):
            guard let data = try contextFetch(path: id) else {
                return nil
            }
            return data
        case .tag(let name, let parameters, let body, let chained):
            return try renderTag(name: name, parameters: parameters, body: body, chained: chained)
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

    private func contextFetch(path: [String]) throws -> Data? {
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

