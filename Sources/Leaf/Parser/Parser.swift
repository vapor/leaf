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

    private func extractSyntax(untilUnescaped signalBytes: Bytes = []) throws -> Syntax? {
        guard let byte = scanner.peek() else {
            return nil
        }

        let syntax: Syntax

        if byte == .numberSign {
            if try shouldExtractTag() {
                try expect(.numberSign)
                syntax = try extractTag()
            } else {
                let byte = try scanner.requirePop()
                let start = scanner.makeSourceStart()
                let bytes = try [byte] + extractRaw(untilUnescaped: signalBytes)
                let source = scanner.makeSource(using: start)
                syntax = Syntax(kind: .raw(data: bytes), source: source)
            }
        } else {
            let start = scanner.makeSourceStart()
            let bytes = try extractRaw(untilUnescaped: signalBytes)
            let source = scanner.makeSource(using: start)
            syntax = Syntax(kind: .raw(data: bytes), source: source)
        }

        return syntax
    }

    private func shouldExtractTag() throws -> Bool {
        var i = 1
        var previous: Byte?
        while let byte = scanner.peek(by: i) {
            if byte == .forwardSlash || byte == .asterisk {
                if previous == .forwardSlash {
                    return true
                }
            } else if byte == .leftParenthesis {
                return true
            } else if !byte.isAllowedInIdentifier {
                return false
            }
            previous = byte
            i += 1
        }
        return false
    }

    private func shouldExtractBody() throws -> Bool {
        var i = 1
        while let byte = scanner.peek(by: i) {
            if byte == .leftCurlyBracket {
                return true
            }
            if byte != .space {
                return false
            }
            i += 1
        }
        return false
    }

    private func shouldExtractChainedTag() throws -> Bool {
        var i = 1
        var previous: Byte?
        while let byte = scanner.peek(by: i) {
            if byte == .numberSign && previous == .numberSign {
                return true
            }
            if byte != .space && byte != .numberSign {
                return false
            }
            previous = byte
            i += 1
        }
        return false
    }

    private func extractTag() throws -> Syntax {
        let start = scanner.makeSourceStart()
        let indent = scanner.column - 1

        // NAME

        let id = try extractTagName()
        
        // verify tag names containg / or * are comment tag names
        if id.contains(where: { $0 == .forwardSlash || $0 == .asterisk }) {
            switch id {
            case [.forwardSlash, .forwardSlash], [.forwardSlash, .asterisk]:
                break
            default:
                throw ParserError.expectationFailed(expected: "Valid tag name", got: id.makeString())
            }
        }

        // PARAMS

        let params: [Syntax]
        let name = id.makeString()

        switch name {
        case "for":
            try expect(.leftParenthesis)
            let key = try extractIdentifier()
            try expect(.space)
            try expect(.i)
            try expect(.n)
            try expect(.space)
            guard let val = try extractParameter() else {
                throw ParserError.expectationFailed(expected: "right parameter", got: "nil")
            }

            switch val.kind {
            case .identifier, .tag:
                break
            default:
                throw ParserError.expectationFailed(expected: "identifier or tag", got: "\(val)")
            }

            try expect(.rightParenthesis)

            guard case .identifier(let name) = key.kind else {
                throw ParserError.expectationFailed(expected: "key name", got: "\(key)")
            }

            guard name.count == 1 else {
                throw ParserError.expectationFailed(expected: "single key", got: "\(name)")
            }

            let raw = Syntax(
                kind: .raw(data: name[0].makeBytes()),
                source: key.source
            )

            let keyConstant = Syntax(
                kind: .constant(.string([raw])),
                source: key.source
            )

            params = [
                val,
                keyConstant
            ]
        case "//", "/*":
            params = []
        default:
            params = try extractParameters()
        }

        // BODY

        let body: [Syntax]?
        if name == "//" {
            let s = scanner.makeSourceStart()
            let bytes = try extractBytes(untilUnescaped: [.newLine])
            // pop the newline
            try scanner.requirePop()
            body = [Syntax(
                kind: .raw(data: bytes),
                source: scanner.makeSource(using: s)
            )]
        } else if name == "/*" {
            let s = scanner.makeSourceStart()
            var i = 0
            var previous: Byte?
            while let byte = scanner.peek(by: i) {
                if byte == .forwardSlash && previous == .asterisk {
                    break
                }
                previous = byte
                i += 1
            }

            // pop comment text, w/o trailing */
            try scanner.requirePop(n: i - 1)

            let bytes = Array(scanner.bytes[s.rangeStart..<scanner.offset])

            // pop */
            try scanner.requirePop(n: 2)

            body = [Syntax(
                kind: .raw(data: bytes),
                source: scanner.makeSource(using: s)
            )]
        } else {
            if try shouldExtractBody() {
                try skipWhitespace()
                body = try extractBody(indent: indent)
            } else {
                body = nil
            }
        }

        // KIND

        let kind: SyntaxKind

        switch name {
        case "if":
            let chained = try extractIfElse(indent: indent)
            kind = .tag(
                name: "ifElse",
                parameters: params,
                indent: indent,
                body: body,
                chained: chained
            )
        case "for":
            kind = .tag(
                name: "loop",
                parameters: params,
                indent: indent,
                body: body,
                chained: nil
            )
        case "//", "/*":
            kind = .tag(
                name: "comment",
                parameters: params,
                indent: indent,
                body: body,
                chained: nil
            )
        default:
            var chained: Syntax?

            if try shouldExtractChainedTag() {
                try skipWhitespace()
                try expect(.numberSign)
                try expect(.numberSign)
                chained = try extractTag()
            }

            kind = .tag(
                name: name,
                parameters: params,
                indent: indent,
                body: body,
                chained: chained
            )
        }

        let source = scanner.makeSource(using: start)
        return Syntax(kind: kind, source: source)
    }

    private func extractIfElse(indent: Int) throws -> Syntax? {
        try skipWhitespace()
        let start = scanner.makeSourceStart()

        if scanner.peekMatches([.e, .l, .s, .e]) {
            try scanner.requirePop(n: 4)
            try skipWhitespace()

            let params: [Syntax]
            if scanner.peekMatches([.i, .f]) {
                try scanner.requirePop(n: 2)
                try skipWhitespace()
                params = try extractParameters()
            } else {
                let syntax = Syntax(
                    kind: .constant(.bool(true)),
                    source: Source(line: scanner.line, column: scanner.column, range: scanner.offset..<scanner.offset + 1
                ))
                params = [syntax]
            }
            try skipWhitespace()
            let elseBody = try extractBody(indent: indent)

            let kind: SyntaxKind = .tag(
                name: "ifElse",
                parameters: params,
                indent: indent,
                body: elseBody,
                chained: try extractIfElse(indent: indent)
            )

            let source = scanner.makeSource(using: start)
            return Syntax(kind: kind, source: source)
        }

        return nil
    }

    private func extractBody(indent: Int) throws -> [Syntax] {
        try expect(.leftCurlyBracket)

        var ast: [Syntax] = []
        while let syntax = try extractSyntax(untilUnescaped: [.rightCurlyBracket]) {
            ast.append(syntax)
            if scanner.peek() == .rightCurlyBracket {
                break
            }
        }
        try expect(.rightCurlyBracket)

        // fix indentation
        if let first = ast.first {
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
                ast[0] = Syntax(kind: .raw(data: raw), source: first.source)
            }
        }
        if let last = ast.last {
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
                ast[ast.count - 1] = Syntax(kind: .raw(data: raw), source: last.source)
            }
        }

        return ast
    }

    private func extractRaw(untilUnescaped signalBytes: Bytes) throws -> Bytes {
        return try extractBytes(untilUnescaped: signalBytes + [.numberSign])
    }

    private func extractBytes(untilUnescaped signalBytes: Bytes) throws -> Bytes {
        // needs to be an array for the time being b/c we may skip
        // bytes
        var bytes: Bytes = []

        // continue to peek until we fine a signal byte, then exit!
        // the inner loop takes care that we will not hit any
        // properly escaped signal bytes
        while let byte = scanner.peek(), !signalBytes.contains(byte) {
            // pop the byte we just peeked at
            try scanner.requirePop()

            // if the current byte is a backslash, then
            // we need to check if next byte is a signal byte
            if byte == .backSlash {
                // check if the next byte is a signal byte
                if let next = scanner.peek(), signalBytes.contains(next) {
                    // if it is, it has been properly escaped.
                    // add it now, skipping the backslash and popping
                    // so the next iteration of this loop won't see it
                    bytes.append(next)
                    try scanner.requirePop()
                } else {
                    // just a normal backslash
                    bytes.append(byte)
                }
            } else {
                // just a normal byte
                bytes.append(byte)
            }
        }

        return bytes
    }

    private func extractIdentifier() throws -> Syntax {
        let start = scanner.makeSourceStart()

        var path: [String] = []
        var current: Bytes = []

        while let byte = scanner.peek(), byte.isAllowedInIdentifier {
           try scanner.requirePop()
            switch byte {
            case .period:
                path.append(current.makeString())
                current = []
            default:
                current.append(byte)
            }
        }
        path.append(current.makeString())
        
        let kind: SyntaxKind = .identifier(path: path)
        let source = scanner.makeSource(using: start)
        return Syntax(kind: kind, source: source)
    }

    private func extractTagName() throws -> Bytes {
        let start = scanner.offset

        while let byte = scanner.peek(), byte.isAllowedInTagName {
            try scanner.requirePop()
        }

        return Array(scanner.bytes[start..<scanner.offset])
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
            let bytes = try extractBytes(untilUnescaped: [.quote])
            try expect(.quote)
            let parser = Parser(bytes)
            let ast = try parser.parse()
            kind = .constant(
                .string(ast)
            )
        case .exclamation:
            try expect(.exclamation)
            guard let param = try extractParameter() else {
                throw ParserError.expectationFailed(expected: "parameter", got: "nil")
            }
            kind = .not(param)
        default:
            if byte.isDigit || byte == .hyphen {
                // constant number
                let num = try extractNumber()
                kind = .constant(num)
            } else if scanner.peekMatches([.t, .r, .u, .e]) {
                try scanner.requirePop(n: 4)
                kind = .constant(.bool(true))
            } else if scanner.peekMatches([.f, .a, .l, .s, .e]) {
                try scanner.requirePop(n: 5)
                kind = .constant(.bool(false))
            } else if try shouldExtractTag() {
                kind = try extractTag().kind
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
                    case .asterisk:
                        op = .multiply
                    case .forwardSlash:
                        op = .divide
                    case .equals:
                        op = .equal
                    case .exclamation:
                        op = .notEqual
                    default:
                        op = nil
                    }
                } else {
                    op = nil
                }

                if let op = op {
                    try scanner.requirePop()

                    switch op {
                    case .equal, .notEqual:
                        // should expect another equals sign
                        try expect(.equals)
                    default:
                        break
                    }

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

    func requirePop(n: Int) throws {
        for _ in 0..<n {
            try requirePop()
        }
    }

    func peekMatches(_ bytes: Bytes) -> Bool {
        var iterator = bytes.makeIterator()
        var i = 0
        while let next = iterator.next() {
            switch peek(by: i) {
            case next:
                i += 1
                continue
            default:
                return false
            }
        }

        return true
    }
}
