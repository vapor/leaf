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
            switch syntax {
            case .raw(let data):
                serialized += data
            case .tag(let name, let parameters, let body):
                guard case .identifier(let id) = name else {
                    throw "tag name must be identifier"
                }

                guard let tag = renderer.tags[id] else {
                    throw "no tag found named \(id)"
                }

                var inputs: [Data] = []

                for parameter in parameters {
                    let input = try resolveSyntax(parameter)
                    inputs.append(input)
                }

                let renderedBody: Bytes?
                if let body = body {
                    let serializer = Serializer(ast: body, renderer: renderer, context: context)
                    renderedBody = try serializer.serialize()
                } else {
                    renderedBody = nil
                }

                let data = try tag.render(
                    parameters: inputs,
                    context: &context,
                    body: renderedBody,
                    renderer: renderer
                )
                serialized += data

            default:
                throw "unexpected syntax"
            }
        }

        return serialized
    }

    func resolveConstant(_ const: Constant) throws -> Data {
        switch const {
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

    func resolveExpression(_ op: Operator, left: Syntax, right: Syntax) throws -> Data {
        let left = try resolveSyntax(left)
        let right = try resolveSyntax(right)

        guard let leftDouble = left.double else {
            throw "could not resolve left argument to number: \(left)"
        }

        guard let rightDouble = right.double else {
            throw "could not resolve right argument to number: \(right)"
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
        }
    }

    func resolveSyntax(_ syntax: Syntax) throws -> Data {
        switch syntax {
        case .constant(let constant):
            return try resolveConstant(constant)
        case .expression(let op, let left, let right):
            return try resolveExpression(op, left: left, right: right)
        case .identifier(let id):
            guard let data = context.dictionary?[id] else {
                throw "could not resolve \(id)"
            }

            return data
        default:
            throw "unsupported syntax: \(syntax)"
        }
    }
}

