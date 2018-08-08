import Bits

/// Parses leaf templates into a cacheable AST
/// that can be later combined with Leaf Data to
/// serialized a View.
internal final class LeafParser: TemplateParser {
    /// Creates a new Leaf parser
    internal init() { }

    /// Parses the AST.
    /// throws `RenderError`. 
    internal func parse(scanner: TemplateByteScanner) throws -> [TemplateSyntax] {
        var ast: [TemplateSyntax] = []

        /// start parsing syntax
        while let syntax = try scanner.extractSyntax() {
            ast.append(syntax)
        }
        print(ast)
        
        return ast
    }
}

// MARK: Private

extension TemplateByteScanner {
    /// Base level extraction. Checks for `#` or extracts raw.
    fileprivate func extractSyntax(untilUnescaped signalBytes: Bytes = []) throws -> TemplateSyntax? {
        guard let byte = peek() else {
            return nil
        }

        let syntax: TemplateSyntax

        if byte == .numberSign {
            if try shouldExtractTag() {
                try expect(.numberSign)
                syntax = try extractTag()
            } else {
                let byte = try requirePop()
                let start = makeSourceStart()
                let bytes = try Data(bytes: [byte]) + extractRaw(untilUnescaped: signalBytes)
                let source = makeSource(using: start)
                syntax = TemplateSyntax(
                    type: .raw(TemplateRaw(data: bytes)),
                    source: source
                )
            }
        } else {
            let start = makeSourceStart()
            let bytes = try extractRaw(untilUnescaped: signalBytes)
            let source = makeSource(using: start)
            syntax = TemplateSyntax(
                type: .raw(TemplateRaw(data: bytes)),
                source: source
            )
        }
        return syntax
    }

    /// Checks ahead to see if a tag should be parsed.
    ///
    /// Avoids parsing if like `#foo`. Must be in format `#tag()`
    private func shouldExtractTag() throws -> Bool {
        var i = 1
        var previous: Byte?
        while let byte = peek(by: i) {
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

    /// Checks ahead to see if a body should be parsed.
    /// fixme: should fix `\{`
    private func shouldExtractBody() throws -> Bool {
        var i = 0
        while let byte = peek(by: i) {
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

    /// Checks ahead to see if a chained tag `##if` should be parsed.
    private func shouldExtractChainedTag() throws -> Bool {
        var i = 1
        var previous: Byte?
        while let byte = peek(by: i) {
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

    /// Extracts a tag, recursively extracting chained tags and tag parameters and bodies.
    private func extractTag() throws -> TemplateSyntax {
        let start = makeSourceStart()

        /// Extract the tag name.
        let id = try extractTagName()
        
        // Verify tag names containg / or * are comment tag names.
        if id.contains(where: { $0 == .forwardSlash || $0 == .asterisk }) {
            switch id {
            case Data(bytes: [.forwardSlash, .forwardSlash]), Data(bytes: [.forwardSlash, .asterisk]):
                break
            default:
                throw TemplateKitError(identifier: "parse", reason: "Invalid tag name", source: makeSource(using: start))
            }
        }

        // Extract the tag params.
        let params: [TemplateSyntax]
        guard let name = String(data: id, encoding: .utf8) else {
            throw TemplateKitError(identifier: "parse", reason: "Invalid UTF-8 string", source: makeSource(using: start))
        }

        switch name {
        case "for":
            try expect(.leftParenthesis)
            if peek() == .space {
                throw TemplateKitError(identifier: "parse",
                    reason: "Whitespace not allowed before key in 'for' tag.",
                    source: makeSource(using: start)
                )
            }
            let key = try extractIdentifier()
            try expect(.space)
            try expect(.i)
            try expect(.n)
            try expect(.space)
            guard let val = try extractParameter() else {
                throw TemplateKitError(identifier: "parse", reason: "Parameter required after `in` in for-loop", source: makeSource(using: start))
            }

            switch val.type {
            case .identifier, .tag:
                break
            default:
                throw TemplateKitError(identifier: "parse", reason: "Identifier or tag required", source: makeSource(using: start))
            }

            if peek(by: -1) == .space {
                throw TemplateKitError(identifier: "parse",
                    reason: "Whitespace not allowed after value in 'for' tag.",
                    source: makeSource(using: start)
                )
            }
            try expect(.rightParenthesis)

            guard case .identifier(let name) = key.type else {
                throw TemplateKitError(identifier: "parse", reason: "Invalid key type in for-loop", source: makeSource(using: start))
            }

            guard name.path.count == 1 else {
                throw TemplateKitError(identifier: "parse", reason: "One key required in for-loop", source: makeSource(using: start))
            }

            let keyConstant = TemplateSyntax(
                type: .constant(.string(name.path[0].stringValue)),
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

        // Extract tag body.
        let body: [TemplateSyntax]?
        if name == "//" {
            let s = makeSourceStart()
            let bytes = try extractBytes(untilUnescaped: [.newLine])
            // pop the newline
            try requirePop()
            body = [TemplateSyntax(
                type: .raw(TemplateRaw(data: bytes)),
                source: makeSource(using: s)
            )]
        } else if name == "/*" {
            let s = makeSourceStart()
            var i = 0
            var previous: Byte?
            while let byte = peek(by: i) {
                if byte == .forwardSlash && previous == .asterisk {
                    break
                }
                previous = byte
                i += 1
            }

            // pop comment text, w/o trailing */
            try requirePop(n: i - 1)

            let bytes = data[s.offset..<offset]

            // pop */
            try requirePop(n: 2)

            body = [TemplateSyntax(
                type: .raw(TemplateRaw(data: bytes)),
                source: makeSource(using: s)
            )]
        } else {
            if try shouldExtractBody() {
                try extractSpaces()
                body = try extractBody()
            } else {
                body = nil
            }
        }

        // Convert to syntax type

        let type: TemplateSyntaxType

        switch name {
        case "if":
            guard params.count == 1 else {
                throw TemplateKitError(identifier: "parse", reason: "One parameter required for if tag.", source: makeSource(using: start))
            }

            let cond = try TemplateConditional(
                condition: params[0],
                body: body ?? [],
                next: extractIfElse()
            )
            type = .conditional(cond)
        case "embed":
            guard params.count == 1 else {
                throw TemplateKitError(identifier: "parse", reason: "One parameter required for embed tag.", source: makeSource(using: start))
            }
            let embed = TemplateEmbed(path: params[0])
            type = .embed(embed)
        case "for":
            guard params.count == 2 else {
                throw TemplateKitError(identifier: "parse", reason: "Two parameters required for for-loop.", source: makeSource(using: start))
            }
            let iterator = TemplateIterator(key: params[1], data: params[0], body: body ?? [])
            type = .iterator(iterator)
        case "//", "/*":
            // omit comments
            type = .raw(TemplateRaw(data: .empty))
        default:
            let tag = TemplateTag(
                name: name,
                parameters: params,
                body: body
            )
            type = .tag(tag)
        }

        let source = makeSource(using: start)
        return TemplateSyntax(type: type, source: source)
    }

    // extracts if/else syntax sugar
    private func extractIfElse() throws -> TemplateConditional? {
        let start = makeSourceStart()

        try extractSpaces()
        if peekMatches([.e, .l, .s, .e]) {
            try requirePop(n: 4)
            try extractSpaces()

            let params: [TemplateSyntax]
            if peekMatches([.i, .f]) {
                try requirePop(n: 2)
                try extractSpaces()
                params = try extractParameters()
            } else {
                let syntax = TemplateSyntax(
                    type: .constant(.bool(true)),
                    source: makeSource(using: makeSourceStart())
                )
                params = [syntax]
            }
            try extractSpaces()

            guard params.count == 1 else {
                throw TemplateKitError(identifier: "parse", reason: "One parameter required for else tag.", source: makeSource(using: start))
            }

            return try TemplateConditional(
                condition: params[0],
                body: extractBody(),
                next: extractIfElse()
            )
        }

        return nil
    }

    // extracts a tag body { to }
    private func extractBody() throws -> [TemplateSyntax] {
        try expect(.leftCurlyBracket)

        var ast: [TemplateSyntax] = []
        while let syntax = try extractSyntax(untilUnescaped: [.rightCurlyBracket]) {
            ast.append(syntax)
            if peek() == .rightCurlyBracket {
                break
            }
        }

        try expect(.rightCurlyBracket)
        return ast
    }

    // extracts a raw chunk of text (until unescaped number sign)
    private func extractRaw(untilUnescaped signalBytes: [Byte]) throws -> Data {
        return try extractBytes(untilUnescaped: signalBytes + [.numberSign])
    }

    // extracts bytes until an unescaped signal byte is found.
    // note: escaped bytes have the leading `\` removed
    private func extractBytes(untilUnescaped signalBytes: [Byte]) throws -> Data {
        // needs to be an array for the time being b/c we may skip
        // bytes
        var bytes: Data = Data()

        var onlySpacesExtracted = true

        // continue to peek until we fine a signal byte, then exit!
        // the inner loop takes care that we will not hit any
        // properly escaped signal bytes
        while let byte = peek(), !signalBytes.contains(byte) {
            // pop the byte we just peeked at
            try requirePop()

            // if the current byte is a backslash, then
            // we need to check if next byte is a signal byte
            if byte == .backSlash {
                // check if the next byte is a signal byte
                // note: special case, any raw leading with a left curly must
                // be properly escaped (have the \ removed)
                if let next = peek(), signalBytes.contains(next) || onlySpacesExtracted && next == .leftCurlyBracket {
                    // if it is, it has been properly escaped.
                    // add it now, skipping the backslash and popping
                    // so the next iteration of this loop won't see it
                    bytes.append(next)
                    try requirePop()
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

    // extracts a string of characters allowed in identifier
    private func extractIdentifier() throws -> TemplateSyntax {
        let start = makeSourceStart()

        var path: [String] = []
        var current: String = ""

        while let byte = peek(), byte.isAllowedInIdentifier {
           try requirePop()
            switch byte {
            case .period:
                path.append(current)
                current = ""
            default:
                current.append(byte.string)
            }
        }
        path.append(current)

        let id = TemplateIdentifier(path: path.map(BasicKey.init))
        return TemplateSyntax(
            type: .identifier(id),
            source: makeSource(using: start)
        )
    }

    // extracts a string of characters allowed in tag names
    private func extractTagName() throws -> Data {
        let start = offset

        while let byte = peek(), byte.isAllowedInTagName {
            try requirePop()
        }

        return data[start..<offset]
    }

    // extracts parameters until closing right parens is found
    private func extractParameters() throws -> [TemplateSyntax] {
        try expect(.leftParenthesis)

        var params: [TemplateSyntax] = []
        repeat {
            if params.count > 0 {
                try expect(.comma)
            }

            if let param = try extractParameter() {
                params.append(param)
            }
        } while peek() == .comma

        try expect(.rightParenthesis)

        return params
    }

    // extracts a raw number
    private func extractNumber() throws -> TemplateConstant {
        let start = makeSourceStart()

        while let byte = peek(), byte.isDigit || byte == .period || byte == .hyphen {
            try requirePop()
        }

        let bytes = data[start.offset..<offset]
        guard let string = String(data: bytes, encoding: .utf8) else {
            throw TemplateKitError(identifier: "parse", reason: "Invalid UTF8 string", source: makeSource(using: start))
        }
        if bytes.contains(.period) {
            guard let double = Double(string) else {
                throw TemplateKitError(identifier: "parse", reason: "Invalid double", source: makeSource(using: start))
            }
            return .double(double)
        } else {
            guard let int = Int(string) else {
                throw TemplateKitError(identifier: "parse", reason: "Invalid integer", source: makeSource(using: start))
            }
            return .int(int)
        }

    }

    // extracts a single tag parameter. this is recursive.
    private func extractParameter() throws -> TemplateSyntax? {
        try extractSpaces()
        let start = makeSourceStart()

        guard let byte = peek() else {
            throw TemplateKitError(identifier: "parse", reason: "Unexpected EOF", source: makeSource(using: start))
        }

        let kind: TemplateSyntaxType

        switch byte {
        case .rightParenthesis:
            return nil
        case .quote:
            try expect(.quote)
            let bytes = try extractBytes(untilUnescaped: [.quote])
            try expect(.quote)
            let ast = try LeafParser().parse(scanner: TemplateByteScanner(data: bytes, file: file))
            kind = .constant(.interpolated(ast))
        case .exclamation:
            try expect(.exclamation)
            guard let param = try extractParameter() else {
                throw TemplateKitError(identifier: "parse", reason: "Parameter required after not `!`", source: makeSource(using: start))
            }
            kind = .expression(.prefix(op: .not, right: param))
        default:
            if byte.isDigit || byte == .hyphen {
                // constant number
                let num = try extractNumber()
                kind = .constant(num)
            } else if peekMatches([.t, .r, .u, .e]) {
                try requirePop(n: 4)
                kind = .constant(.bool(true))
            } else if peekMatches([.f, .a, .l, .s, .e]) {
                try requirePop(n: 5)
                kind = .constant(.bool(false))
            } else if try shouldExtractTag() {
                kind = try extractTag().type
            } else {
                let id = try extractIdentifier()
                kind = id.type
            }
        }

        let syntax = TemplateSyntax(type: kind, source: makeSource(using: start))

        try extractSpaces()

        let op: TemplateExpression.InfixOperator?

        if let byte = peek() {
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
            case .percent:
                op = .modulo
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
            try requirePop()

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
                throw TemplateKitError(identifier: "parse", reason: "Parameter required after infix operator", source: makeSource(using: start))
            }

            // FIXME: add support for parens
            
            if case .expression(let rexp) = right.type, case .infix(let rop, let rleft, let rright) = rexp, rop.order >= op.order {
                let lleft = syntax
                let lop = op
                let nleft = TemplateSyntax(type: .expression(.infix(op: lop, left: lleft, right: rleft)), source: makeSource(using: start))
                let source = makeSource(using: start)
                return TemplateSyntax(type: .expression(.infix(
                    op: rop,
                    left: nleft,
                    right: rright
                )), source: source)
            } else {
                let source = makeSource(using: start)
                return TemplateSyntax(type: .expression(.infix(
                    op: op,
                    left: syntax,
                    right: right
                )), source: source)
            }
        } else {
            return syntax
        }

    }

    // extracts all spaces. used for extracting: `#tag()__{`
    private func extractSpaces() throws {
        while let byte = peek(), byte == .space {
            try requirePop()
        }
    }

    // expects the supplied byte is current byte or throws an error
    private func expect(_ expect: Byte) throws {
        let start = makeSourceStart()

        guard let byte = peek() else {
            throw TemplateKitError(identifier: "parse", reason: "Unexpected EOF", source: makeSource(using: start))
        }

        guard byte == expect else {
            let expectedChar = Character(Unicode.Scalar.init(expect))
            let char = Character(Unicode.Scalar.init(byte))
            throw TemplateKitError(identifier: "parse", reason: "Expected '\(expectedChar)' got '\(char)'", source: makeSource(using: start))
        }

        try requirePop()
    }
}

// mark: file private scanner conveniences
