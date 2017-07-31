import Bits

final class Parser {
    let scanner: ByteScanner

    init(_ data: Bytes) {
        self.scanner = ByteScanner(data)
    }

    func parse() throws -> [Syntax] {
        var ast: [Syntax] = []

        var start = scanner.offset
        do {
            while let syntax = try extractSyntax() {
                start = scanner.offset
                ast.append(syntax)
            }
        } catch {
            throw RenderError(
                source: Source(
                    line: scanner.line,
                    column: scanner.column,
                    range: start..<scanner.offset
                ),
                error: error
            )
        }

        return ast
    }

    private func extractSyntax() throws -> Syntax? {
        guard let byte = scanner.peek() else {
            return nil
        }

        let syntax: Syntax

        switch byte {
        case .numberSign:
            syntax = try extractTag()
        default:
            let start = scanner.makeSourceStart()
            let bytes = try extractRaw()
            let source = scanner.makeSource(using: start)
            return Syntax(kind: .raw(data: bytes), source: source)
        }

        return syntax
    }

    private func extractTag() throws -> Syntax {
        let start = scanner.makeSourceStart()

        let indent = scanner.column

        try expect(.numberSign)
        let id = try extractIdentifier()
        let params = try extractParameters()
        try skipWhitespace()

        let body: [Syntax]?

        if let byte = scanner.peek() {
            if byte == .leftCurlyBracket {
                var tempBody = try extractBody()

                // fix indentation
                if let first = tempBody.first {
                    if case .raw(var raw) = first.kind {
                        if raw.first == .newLine {
                            raw = Array(raw.dropFirst())
                        }
                        var removedSpaces = 0
                        while raw.first == .space {
                            raw = Array(raw.dropFirst())
                            removedSpaces += 1
                            if removedSpaces == indent + 4 {
                                break
                            }
                        }
                        tempBody[0] = Syntax(kind: .raw(data: raw), source: first.source)
                    }
                }
                if let last = tempBody.last {
                    if case .raw(var raw) = last.kind {
                        var removedSpaces = 0
                        while raw.last == .space {
                            raw = Array(raw.dropLast())
                            removedSpaces += 1
                            if removedSpaces == indent {
                                break
                            }
                        }

                        if raw.last == .newLine {
                            raw = Array(raw.dropLast())
                        }
                        tempBody[tempBody.count - 1] = Syntax(kind: .raw(data: raw), source: last.source)
                    }
                }


                body = tempBody
            } else {
                body = nil
            }
        } else {
            body = nil
        }

        var chained: Syntax?

        try skipWhitespace()
        switch scanner.peek() {
        case Byte.numberSign:
            switch scanner.peek() {
            case Byte.numberSign:
                // found double ##
                try expect(.numberSign)
                chained = try extractTag()
            default:
                break
            }
        default:
            break
        }

        let kind: SyntaxKind = .tag(
            name: id,
            parameters: params,
            indent: indent,
            body: body,
            chained: chained
        )

        let source = scanner.makeSource(using: start)
        return Syntax(kind: kind, source: source)
    }

    private func extractBody() throws -> [Syntax] {
        try expect(.leftCurlyBracket)
        let body = try bytes(until: .rightCurlyBracket)
        try expect(.rightCurlyBracket)
        let parser = Parser(body)
        return try parser.parse()
    }

    private func extractRaw() throws -> Bytes {
        return try bytes(until: .numberSign)
    }

    private func bytes(until: Byte) throws -> Bytes {
        var previous: Byte?

        var bytes: Bytes = []
        while let byte = scanner.peek(), byte != until || previous == .backSlash {
            try scanner.requirePop()
            if byte != until && previous == .backSlash {
                bytes.append(.backSlash)
            }
            if byte != .backSlash {
                bytes.append(byte)
            }
            previous = byte
        }

        return bytes
    }

    private func extractIdentifier() throws -> Syntax {
        let start = scanner.makeSourceStart()

        while let byte = scanner.peek(), byte.isAllowedInIdentifier {
           try scanner.requirePop()
        }
        
        let bytes = scanner.bytes[start.rangeStart..<scanner.offset]
        let kind: SyntaxKind = .identifier(name: bytes.makeString())
        let source = scanner.makeSource(using: start)
        return Syntax(kind: kind, source: source)
    }

    private func extractParameters() throws -> [Syntax] {
        try expect(.leftParenthesis)

        var params: [Syntax] = []
        repeat {
            if params.count > 0 {
                try expect(.comma)
            }

            if let param = try extractParameter() {
                params.append(param)
            }
        } while scanner.peek() == .comma

        try expect(.rightParenthesis)

        return params
    }

    private func extractNumber() throws -> Constant {
        let start = scanner.offset
        while let byte = scanner.peek(), byte.isDigit || byte == .period || byte == .hyphen {
            try scanner.requirePop()
        }

        let bytes = scanner.bytes[start..<scanner.offset]
        let string = bytes.makeString()
        if bytes.contains(.period) {
            guard let double = Double(string) else {
                throw ParserError.expectationFailed(expected: "double", got: string)
            }
            return .double(double)
        } else {
            guard let int = Int(string) else {
                throw ParserError.expectationFailed(expected: "integer", got: string)
            }
            return .int(int)
        }

    }

    private func extractParameter() throws -> Syntax? {
        try skipWhitespace()
        let start = scanner.makeSourceStart()

        guard let byte = scanner.peek() else {
            throw ParserError.expectationFailed(expected: "bytes", got: "EOF")
        }

        let kind: SyntaxKind

        switch byte {
        case .rightParenthesis:
            return nil
        case .quote:
            try expect(.quote)
            let bytes = try self.bytes(until: .quote)
            try expect(.quote)
            let parser = Parser(bytes)
            let ast = try parser.parse()
            kind = .constant(
                .string(ast)
            )
        case .numberSign:
            kind = try extractTag().kind
        default:
            if byte.isDigit || byte == .hyphen {
                // constant number
                let num = try extractNumber()
                kind = .constant(num)
            } else {
                let id = try extractIdentifier()

                try skipWhitespace()

                let op: Operator?

                if let byte = scanner.peek() {
                    switch byte {
                    case .lessThan:
                        op = .lessThan
                    case .greaterThan:
                        op = .greaterThan
                    case .hyphen:
                        op = .subtract
                    case .plus:
                        op = .add
                    default:
                        op = nil
                    }
                } else {
                    op = nil
                }

                if let op = op {
                    try scanner.requirePop()

                    guard let right = try extractParameter() else {
                        throw ParserError.expectationFailed(expected: "right parameter", got: "nil")
                    }

                    // FIXME: allow for () grouping and proper PEMDAS
                    kind = .expression(
                        type: op,
                        left: id,
                        right: right
                    )
                } else {
                    kind = id.kind
                }
            }
        }

        let source = scanner.makeSource(using: start)
        return Syntax(kind: kind, source: source)
    }

    private func skipWhitespace() throws {
        while let byte = scanner.peek(), byte == .space {
            try scanner.requirePop()
        }
    }

    private func expect(_ expect: Byte) throws {
        guard let byte = scanner.peek() else {
            throw ParserError.unexpectedEOF
        }

        guard byte == expect else {
            throw ParserError.expectationFailed(expected: expect.makeString(), got: byte.makeString())
        }

        try scanner.requirePop()
    }
}

extension ByteScanner {
    @discardableResult
    func requirePop() throws -> Byte {
        guard let byte = pop() else {
            throw ParserError.unexpectedEOF
        }
        return byte
    }
}
