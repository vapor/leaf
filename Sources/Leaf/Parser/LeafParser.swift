import Bits
import CodableKit
import Foundation
import TemplateKit

/// Parses leaf templates into a cacheable AST
/// that can be later combined with Leaf Data to
/// serialized a View.
public final class LeafParser: TemplateParser {
    /// Creates a new Leaf parser
    public init() { }

    /// Parses the AST.
    /// throws `RenderError`. 
    public func parse(template: Data, file: String) throws -> [TemplateSyntax] {
        let scanner = TemplateByteScanner(data: template, file: file)

        /// create empty base syntax element, to simplify logic
        let base = TemplateSyntax(
            type: .raw(TemplateRaw(data: .empty)),
            source: scanner.makeSource(using: scanner.makeSourceStart())
        )
        var ast: [TemplateSyntax] = [base]

        /// start parsing syntax
        while let syntax = try scanner.extractSyntax(indent: 0, previous: &ast[ast.count - 1]) {
            ast.append(syntax)
        }

        return ast
    }
}

extension TemplateByteScanner {
    /// Base level extraction. Checks for `#` or extracts raw.
    fileprivate func extractSyntax(untilUnescaped signalBytes: Bytes = [], indent: Int, previous: inout TemplateSyntax) throws -> TemplateSyntax? {
        guard let byte = peek() else {
            return nil
        }

        let syntax: TemplateSyntax

        if byte == .numberSign {
            if try shouldExtractTag() {
                try expect(.numberSign)
                syntax = try extractTag(indent: indent, previous: &previous)
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
    private func extractTag(indent: Int, previous: inout TemplateSyntax) throws -> TemplateSyntax {
        let start = makeSourceStart()

        trim: if case .raw(var raw) = previous.type {
            var offset = 0

            skipwhitespace: for i in (0..<raw.data.count).reversed() {
                offset = i
                switch raw.data[i] {
                case .space:
                    break
                case .newLine:
                    break skipwhitespace
                default:
                    break trim
                }
            }

            if offset == 0 {
                raw.data = .empty
            } else {
                raw.data = Data(raw.data[0..<offset])
            }

            previous = TemplateSyntax(type: .raw(raw), source: previous.source)
        }

        /// Extract the tag name.
        let id = try extractTagName()
        
        // Verify tag names containg / or * are comment tag names.
        if id.contains(where: { $0 == .forwardSlash || $0 == .asterisk }) {
            switch id {
            case Data(bytes: [.forwardSlash, .forwardSlash]), Data(bytes: [.forwardSlash, .asterisk]):
                break
            default:
                throw LeafParserError.expectationFailed(
                    expected: "Valid tag name",
                    got: String(data: id, encoding: .utf8) ?? "n/a",
                    source: makeSource(using: start)
                )
            }
        }

        // Extract the tag params.
        let params: [TemplateSyntax]
        guard let name = String(data: id, encoding: .utf8) else {
            throw LeafParserError.expectationFailed(
                expected: "UTF8 string",
                got: id.description,
                source: makeSource(using: start)
            )
        }

        switch name {
        case "for":
            try expect(.leftParenthesis)
            let key = try extractIdentifier()
            try expect(.space)
            try expect(.i)
            try expect(.n)
            try expect(.space)
            guard let val = try extractParameter() else {
                throw LeafParserError.expectationFailed(
                    expected: "right parameter",
                    got: "nil",
                    source: makeSource(using: start)
                )
            }

            switch val.type {
            case .identifier, .tag:
                break
            default:
                throw LeafParserError.expectationFailed(
                    expected: "identifier or tag",
                    got: "\(val)",
                    source: makeSource(using: start)
                )
            }

            try expect(.rightParenthesis)

            guard case .identifier(let name) = key.type else {
                throw LeafParserError.expectationFailed(
                    expected: "key name",
                    got: "\(key)",
                    source: makeSource(using: start)
                )
            }

            guard name.path.count == 1 else {
                throw LeafParserError.expectationFailed(
                    expected: "single key",
                    got: "\(name)",
                    source: makeSource(using: start)
                )
            }

            guard let data = name.path[0].stringValue.data(using: .utf8) else {
                throw LeafParserError.expectationFailed(
                    expected: "utf8 string",
                    got: name.path[0].stringValue,
                    source: makeSource(using: start)
                )
            }

            let raw = TemplateSyntax(
                type: .raw(TemplateRaw(data: data)),
                source: key.source
            )

            let keyConstant = TemplateSyntax(
                type: .constant(.string([raw])),
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

            let bytes = data[s.rangeStart..<offset]

            // pop */
            try requirePop(n: 2)

            body = [TemplateSyntax(
                type: .raw(TemplateRaw(data: bytes)),
                source: makeSource(using: s)
            )]
        } else {
            if try shouldExtractBody() {
                try extractSpaces()
                let rawBody = try extractBody(indent: indent + 4)
                body = try correctIndentation(rawBody, to: indent)
            } else {
                body = nil
            }
        }

        // Convert to syntax type

        let type: TemplateSyntaxType

        switch name {
        case "if":
            guard params.count == 1 else {
                throw LeafParserError.expectationFailed(
                    expected: "one param",
                    got: "\(params.count) params",
                    source: makeSource(using: start)
                )
            }

            let cond = try TemplateConditional(
                condition: params[0],
                body: body ?? [],
                next: extractIfElse(indent: indent)
            )
            type = .conditional(cond)
        case "embed":
            guard params.count == 1 else {
                throw LeafParserError.expectationFailed(
                    expected: "one param",
                    got: "\(params.count) params",
                    source: makeSource(using: start)
                )
            }
            let embed = TemplateEmbed(path: params[0])
            type = .embed(embed)
        case "for":
            guard params.count == 2 else {
                throw LeafParserError.expectationFailed(
                    expected: "two param",
                    got: "\(params.count) params",
                    source: makeSource(using: start)
                )
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

    // corrects body indentation by splitting on newlines
    // and stitching toogether w/ supplied indent level
    func correctIndentation(_ ast: [TemplateSyntax], to indent: Int) throws -> [TemplateSyntax] {
        var corrected: [TemplateSyntax] = []

        let indent = indent + 4
        
        for syntax in ast {
            switch syntax.type {
            case .raw(let raw):
                let scanner = TemplateByteScanner(data: raw.data, file: file)
                var chunkStart = scanner.offset
                while let byte = scanner.peek() {
                    switch byte {
                    case .newLine:
                        // pop the new line
                        try scanner.requirePop()

                        // break off the previous raw chunk
                        // and remove indentation from following chunk
                        let data = Data(raw.data[chunkStart..<scanner.offset])
                        let new = TemplateSyntax(
                            type: .raw(TemplateRaw(data: data)),
                            source: syntax.source
                        )
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
                if chunkStart < raw.data.count {
                    let data = Data(raw.data[chunkStart..<raw.data.count])
                    let new = TemplateSyntax(
                        type: .raw(TemplateRaw(data: data)),
                        source: syntax.source
                    )
                    corrected.append(new)
                }
            default:
                corrected.append(syntax)
            }
        }

        return Array(corrected)
    }

    // extracts if/else syntax sugar
    private func extractIfElse(indent: Int) throws -> TemplateConditional? {
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
                throw LeafParserError.expectationFailed(
                    expected: "one param",
                    got: "\(params.count) params",
                    source: makeSource(using: start)
                )
            }

            return try TemplateConditional(
                condition: params[0],
                body: extractBody(indent: indent),
                next: extractIfElse(indent: indent)
            )
        }

        return nil
    }

    // extracts a tag body { to }
    private func extractBody(indent: Int) throws -> [TemplateSyntax] {
        try expect(.leftCurlyBracket)

        /// create empty base syntax element, to simplify logic
        let base = TemplateSyntax(
            type: .raw(TemplateRaw(data: .empty)),
            source: makeSource(using: makeSourceStart())
        )
        var ast: [TemplateSyntax] = [base]

        // ast.append(TemplateSyntax(type: .raw(.empty), source: TemplateSource(line: 0, column: 0, range: 0..<1)))
        while let syntax = try extractSyntax(untilUnescaped: [.rightCurlyBracket], indent: indent, previous: &ast[ast.count - 1]) {
            ast.append(syntax)
            if peek() == .rightCurlyBracket {
                break
            }
        }

        trim: if let last = ast.last, case .raw(var raw) = last.type {
            var offset = 0

            skipwhitespace: for i in (0..<raw.data.count).reversed() {
                offset = i
                switch raw.data[i] {
                case .space:
                    break
                case .newLine:
                    break skipwhitespace
                default:
                    break trim
                }
            }

            if offset == 0 {
                raw.data = .empty
            } else {
                raw.data = Data(raw.data[0..<offset])
            }
            ast[ast.count - 1] = TemplateSyntax(type: .raw(raw), source: last.source)
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

        let bytes = data[start.rangeStart..<offset]
        guard let string = String(data: bytes, encoding: .utf8) else {
            throw LeafParserError.expectationFailed(
                expected: "UTF8 string",
                got: bytes.description,
                source: makeSource(using: start)
            )
        }
        if bytes.contains(.period) {
            guard let double = Double(string) else {
                throw LeafParserError.expectationFailed(
                    expected: "double",
                    got: string,
                    source: makeSource(using: start)
                )
            }
            return .double(double)
        } else {
            guard let int = Int(string) else {
                throw LeafParserError.expectationFailed(
                    expected: "integer",
                    got: string,
                    source: makeSource(using: start)
                )
            }
            return .int(int)
        }

    }

    // extracts a single tag parameter. this is recursive.
    private func extractParameter() throws -> TemplateSyntax? {
        try extractSpaces()
        let start = makeSourceStart()

        guard let byte = peek() else {
            throw LeafParserError.expectationFailed(
                expected: "bytes",
                got: "EOF",
                source: makeSource(using: start)
            )
        }

        let kind: TemplateSyntaxType

        switch byte {
        case .rightParenthesis:
            return nil
        case .quote:
            try expect(.quote)
            let bytes = try extractBytes(untilUnescaped: [.quote])
            try expect(.quote)
            let ast = try LeafParser().parse(template: bytes, file: file)
            kind = .constant(
                .string(ast)
            )
        case .exclamation:
            try expect(.exclamation)
            guard let param = try extractParameter() else {
                throw LeafParserError.expectationFailed(
                    expected: "parameter",
                    got: "nil",
                    source: makeSource(using: start)
                )
            }
            kind = .expression(.prefix(operator: .not, right: param))
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
                var syntax = TemplateSyntax(type: .raw(TemplateRaw(data: .empty)), source: makeSource(using: makeSourceStart()))
                kind = try extractTag(indent: 0, previous: &syntax).type
            } else {
                let id = try extractIdentifier()
                kind = id.type
            }
        }

        let syntax = TemplateSyntax(type: kind, source: makeSource(using: start))

        try extractSpaces()

        let op: ExpressionInfixOperator?

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
                throw LeafParserError.expectationFailed(
                    expected: "right parameter",
                    got: "nil",
                    source: makeSource(using: start)
                )
            }

            // FIXME: allow for () grouping and proper PEMDAS
            let exp: TemplateSyntaxType = .expression(.infix(
                operator: op,
                left: syntax,
                right: right
            ))
            let source = makeSource(using: start)
            return TemplateSyntax(type: exp, source: source)
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
            throw LeafParserError.unexpectedEOF(source: makeSource(using: start))
        }

        guard byte == expect else {
            throw LeafParserError.expectationFailed(
                expected: expect.string,
                got: byte.string,
                source: makeSource(using: start)
            )
        }

        try requirePop()
    }
}

// mark: file private scanner conveniences
