import Bits

final class Parser {
    let scanner: ByteScanner

    init(_ data: Bytes) {
        //let data = try! Parser.fix(data)
        print(data.makeString())
        self.scanner = ByteScanner(data)
    }

    static func fix(_ bytes: Bytes) throws -> Bytes {
        var fixed: [(byte: Byte, shouldInclude: Bool)] = []
        let scanner = ByteScanner(bytes)

        while let byte = scanner.pop() {
            fixed.append((byte, true))

            switch byte {
            case .rightCurlyBracket, .numberSign:
                skipwhitespace: for i in (0..<fixed.count - 1).reversed() {
                    switch fixed[i].byte {
                    case .space, .newLine:
                        fixed[i] = (byte, false)
                    default:
                        break skipwhitespace
                    }
                }
                break
            default:
                break
            }
        }

        return fixed.flatMap { tuple in
            if tuple.shouldInclude {
                return tuple.byte
            } else {
                return nil
            }
        }
    }

    func parse() throws -> [Syntax] {
        var ast: [Syntax] = []
        ast.append(Syntax(kind: .raw([]), source: Source(line: 0, column: 0, range: 0..<1)))

        var start = scanner.offset
        do {
            while let syntax = try extractSyntax(indent: 0, previous: &ast[ast.count - 1]) {
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

    func isWhitespace(_ bytes: Bytes) -> Bool {
        for byte in bytes {
            switch byte {
            case .space, .newLine:
                break
            default:
                return false
            }
        }
        return true
    }

    // base level extraction. checks for `#` or extracts raw
    private func extractSyntax(untilUnescaped signalBytes: Bytes = [], indent: Int, previous: inout Syntax) throws -> Syntax? {
        guard let byte = scanner.peek() else {
            return nil
        }

        let syntax: Syntax

        if byte == .numberSign {
            if try shouldExtractTag() {
                try expect(.numberSign)
                syntax = try extractTag(indent: indent, previous: &previous)
            } else {
                let byte = try scanner.requirePop()
                let start = scanner.makeSourceStart()
                let bytes = try [byte] + extractRaw(untilUnescaped: signalBytes)
                let source = scanner.makeSource(using: start)
                syntax = Syntax(kind: .raw(bytes), source: source)
            }
        } else {
            let start = scanner.makeSourceStart()
            let bytes = try extractRaw(untilUnescaped: signalBytes)
            let source = scanner.makeSource(using: start)
            syntax = Syntax(kind: .raw(bytes), source: source)
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
        var i = 0
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

    private func extractTag(indent: Int, previous: inout Syntax) throws -> Syntax {
        let start = scanner.makeSourceStart()

        if case .raw(var bytes) = previous.kind {
            var offset = 0

            skipwhitespace: for i in (0..<bytes.count).reversed() {
                offset = i
                switch bytes[i] {
                case .space, .newLine:
                    break
                default:
                    break skipwhitespace
                }
            }

            if offset == 0 {
                bytes = []
            } else {
                bytes = Array(bytes[0...offset])
            }
            previous = Syntax(kind: .raw(bytes), source: previous.source)
        }

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
                kind: .raw(name[0].makeBytes()),
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
                kind: .raw(bytes),
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
                kind: .raw(bytes),
                source: scanner.makeSource(using: s)
            )]
        } else {
            if try shouldExtractBody() {
                try extractSpaces()
                var rawBody = try extractBody(indent: indent + 4)
                body = try correctIndentation(rawBody, to: indent)
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
                body: body,
                chained: chained
            )
        case "for":
            kind = .tag(
                name: "loop",
                parameters: params,
                body: body,
                chained: nil
            )
        case "//", "/*":
            kind = .tag(
                name: "comment",
                parameters: params,
                body: body,
                chained: nil
            )
        default:
            var chained: Syntax?

            if try shouldExtractChainedTag() {
                try extractSpaces()
                try expect(.numberSign)
                try expect(.numberSign)
                chained = try extractTag(indent: indent, previous: &previous)
            }

            kind = .tag(
                name: name,
                parameters: params,
                body: body,
                chained: chained
            )
        }

        let source = scanner.makeSource(using: start)
        return Syntax(kind: kind, source: source)
    }

    func correctIndentation(_ ast: [Syntax], to indent: Int) throws -> [Syntax] {
        var corrected: [Syntax] = []

        let indent = indent + 4
        
        for syntax in ast {
            switch syntax.kind {
            case .raw(let bytes):
                let scanner = ByteScanner(bytes)
                var chunkStart = scanner.offset
                while let byte = scanner.peek() {
                    switch byte {
                    case .newLine:
                        // pop the new line
                        try scanner.requirePop()

                        // break off the previous raw chunk
                        // and remove indentation from following chunk
                        let data = Array(bytes[chunkStart..<scanner.offset])
                        let new = Syntax(kind: .raw(data), source: syntax.source)
                        corrected.append(new)

                        var spacesSkipped = 0
                        while scanner.peek() == .space {
                            try scanner.requirePop()
                            spacesSkipped += 1
                            if spacesSkipped >= indent {
                                break
                            }
                        }

                        chunkStart = scanner.offset
                    default:
                        try scanner.requirePop()
                    }
                }

                // append any remaining bytes
                if chunkStart < bytes.count {
                    let data = Array(bytes[chunkStart..<bytes.count])
                    let new = Syntax(kind: .raw(data), source: syntax.source)
                    corrected.append(new)
                }
            default:
                corrected.append(syntax)
            }
        }

//        if let first = corrected.first, case .raw(var bytes) = first.kind {
//            if bytes.first == .newLine {
//                bytes = Array(bytes.dropFirst())
//                corrected[0] = Syntax(kind: .raw(bytes), source: first.source)
//            }
//        }
//
//        if let last = corrected.last, case .raw(var bytes) = last.kind {
//            if bytes.last == .newLine {
//                bytes = Array(bytes.dropLast())
//                corrected[corrected.count - 1] = Syntax(kind: .raw(bytes), source: last.source)
//            }
//        }

        return Array(corrected)
    }

    private func extractIfElse(indent: Int) throws -> Syntax? {
        try extractSpaces()
        let start = scanner.makeSourceStart()

        if scanner.peekMatches([.e, .l, .s, .e]) {
            try scanner.requirePop(n: 4)
            try extractSpaces()

            let params: [Syntax]
            if scanner.peekMatches([.i, .f]) {
                try scanner.requirePop(n: 2)
                try extractSpaces()
                params = try extractParameters()
            } else {
                let syntax = Syntax(
                    kind: .constant(.bool(true)),
                    source: Source(line: scanner.line, column: scanner.column, range: scanner.offset..<scanner.offset + 1
                ))
                params = [syntax]
            }
            try extractSpaces()
            let elseBody = try extractBody(indent: indent)

            let kind: SyntaxKind = .tag(
                name: "ifElse",
                parameters: params,
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
        ast.append(Syntax(kind: .raw([]), source: Source(line: 0, column: 0, range: 0..<1)))
        while let syntax = try extractSyntax(untilUnescaped: [.rightCurlyBracket], indent: indent, previous: &ast[ast.count - 1]) {
            ast.append(syntax)
            if scanner.peek() == .rightCurlyBracket {
                break
            }
        }

        if let last = ast.last, case .raw(var bytes) = last.kind {
            var offset = 0

            skipwhitespace: for i in (0..<bytes.count).reversed() {
                offset = i
                switch bytes[i] {
                case .space, .newLine:
                    break
                default:
                    break skipwhitespace
                }
            }

            if offset == 0 {
                bytes = []
            } else {
                bytes = Array(bytes[0...offset])
            }
            ast[ast.count - 1] = Syntax(kind: .raw(bytes), source: last.source)
        }

        try expect(.rightCurlyBracket)
        return ast
    }

    private func extractRaw(untilUnescaped signalBytes: Bytes) throws -> Bytes {
        return try extractBytes(untilUnescaped: signalBytes + [.numberSign])
    }

    private func extractBytes(untilUnescaped signalBytes: Bytes) throws -> Bytes {
        // needs to be an array for the time being b/c we may skip
        // bytes
        var bytes: Bytes = []

        var onlySpacesExtracted = true

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
                // note: special case, any raw leading with a left curly must
                // be properly escaped (have the \ removed)
                if let next = scanner.peek(), signalBytes.contains(next) || onlySpacesExtracted && next == .leftCurlyBracket {
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

            if byte != .space {
                onlySpacesExtracted = false
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
        try extractSpaces()
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
                var syntax = Syntax(kind: .raw([]), source: Source(line: 0, column: 0, range: 0..<1))
                kind = try extractTag(indent: 0, previous: &syntax).kind
            } else {
                let id = try extractIdentifier()
                kind = id.kind
            }
        }

        let syntax = Syntax(kind: kind, source: scanner.makeSource(using: start))

        try extractSpaces()

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
            case .pipe:
                op = .or
            case .ampersand:
                op = .and
            default:
                op = nil
            }
        } else {
            op = nil
        }

        if let op = op {
            try scanner.requirePop()

            // two byte operators must
            // expect their second byte
            switch op {
            case .equal, .notEqual:
                try expect(.equals)
            case .and:
                try expect(.ampersand)
            case .or:
                try expect(.pipe)
            default:
                break
            }

            guard let right = try extractParameter() else {
                throw ParserError.expectationFailed(expected: "right parameter", got: "nil")
            }

            // FIXME: allow for () grouping and proper PEMDAS
            let exp: SyntaxKind = .expression(
                type: op,
                left: syntax,
                right: right
            )
            let source = scanner.makeSource(using: start)
            return Syntax(kind: exp, source: source)
        } else {
            return syntax
        }

    }

    private func extractSpaces() throws {
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

extension Byte {
    static let pipe: Byte = 0x7C
}
