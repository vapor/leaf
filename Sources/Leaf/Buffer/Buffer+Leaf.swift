public let permittedLeafTagCharacters: Bytes = {
    var permitted = Bytes(.a ... .z)
    permitted += Bytes(.A ... .Z)
    permitted += Bytes(.zero ... .nine)
    // -_.:
    permitted += [
        .hyphen,
        .underscore,
        .period,
        .colon
    ]

    return permitted
}()

extension Buffer {
    mutating func components(stem: Stem) throws -> [Leaf.Component] {
        var comps: [Leaf.Component] = []
        while let next = try nextComponent(stem: stem) {
            if case let .tagTemplate(i) = next, i.isChain {
                guard comps.count > 0 else {
                    throw ParseError.expectedLeadingTemplate(have: nil, line: line, column: column)
                }
                while let last = comps.last {
                    var loop = true

                    comps.removeLast()
                    switch last {
                    // skip whitespace
                    case let .raw(raw) where raw.trimmed(.whitespace).isEmpty:
                        continue
                    default:
                        var mutable = last
                        try mutable.addToChain(i, line: line, column: column)
                        comps.append(mutable)
                        loop = false
                    }

                    if !loop { break }
                }
            } else {
                comps.append(next)
            }
        }
        return comps
    }

    mutating func nextComponent(stem: Stem) throws -> Leaf.Component? {
        guard let _ = current else { return nil }
        if foundTag() {
            let tagTemplate = try extractInstruction(stem: stem)
            return .tagTemplate(tagTemplate)
        } else {
            let raw = nextRawComponent()
            return .raw(raw)
        }
    }

    mutating func extractUntil(_ until: (Element) -> Bool) -> [Element] {
        var collection = Bytes()
        if let current = current {
            guard !until(current) else { return [] }
            collection.append(current)
        }
        while let value = moveForward(), !until(value) {
            collection.append(value)
        }

        return collection
    }

    mutating func nextRawComponent() -> [Element] {
        var collection = Bytes()
        if let current = current {
            if foundTag() { return [] }

            if !escapeCurrent() {
                collection.append(current)
            }
        }

        while let value = moveForward() {
            if foundTag() {
                return collection
            }

            guard !escapeCurrent() else { continue }
            collection.append(value)
        }

        return collection
    }

    private func escapeCurrent() -> Bool {
        return next == TOKEN && current == .backSlash
    }

    private func foundTag() -> Bool {
        guard let current = current, let next = next else { return false }
        // make sure we found a token
        guard current == TOKEN else { return false }
        // make sure said token isn't escaped
        guard previous != .backSlash else { return false }

        // allow left parens, special case, ie: '#(' and any valid name
        // also allow special case double chained
        let isSpecialCase = (next == .leftParenthesis || next == TOKEN)
        return isSpecialCase || permittedLeafTagCharacters.contains(next) 
    }
}

enum ParseError: LeafError {
    case tagTemplateNotFound(name: String)
    case missingBodyOpener(expected: String, have: String?, line: Int, column: Int)
    case missingBodyCloser(expected: String, line: Int, column: Int)
    case expectedOpenParenthesis(line: Int, column: Int)
    case expectedLeadingTemplate(have: Leaf.Component?, line: Int, column: Int)
}

/*
 Syntax
 
 @ + '<bodyName>` + `(` + `<[argument]>` + `)` + ` { ` + <body> + ` }`
 */
extension Buffer {
    mutating func extractInstruction(stem: Stem) throws -> TagTemplate {
        let name = try extractInstructionName()
        let parameters = try extractInstructionParameters()
        
        // check if body exists
        
        // Check for immediate curly brace without whitespace.
        // If there is an immediate brace, do nothing.
        if next != .leftCurlyBracket {
            moveForward()
        }
        
        // Move through any redundant whitespace
        while current?.isWhitespace == true && next?.isWhitespace == true {
             moveForward()
        }
        
        guard next == .leftCurlyBracket else {
            return TagTemplate(name: name, parameters: parameters, body: Leaf?.none)
        }
        
        moveForward() // queue up `{`

        // TODO: Body should be leaf components
        let body = try extractBody()
        moveForward()

        let leaf: Leaf?
        if let tag = stem.tags[name] {
            leaf = try tag.compileBody(stem: stem, raw: body)
        } else {
            leaf = try stem.spawnLeaf(raw: body)
        }
        return TagTemplate(name: name, parameters: parameters, body: leaf)
    }

    mutating func extractInstructionName() throws -> String {
        moveForward() // drop initial token from name. a secondary token implies chain
        let name = extractUntil { $0 == .leftParenthesis }
        guard current == .leftParenthesis else {
            throw ParseError.expectedOpenParenthesis(line: line, column: column)
        }
        
        return name.makeString()
    }

    mutating func extractInstructionParameters() throws -> [Parameter] {
        return try extractSection(opensWith: .leftParenthesis, closesWith: .rightParenthesis)
            .extractParameters()
    }

    mutating func extractBody() throws -> String {
        return try extractSection(opensWith: .leftCurlyBracket, closesWith: .rightCurlyBracket)
            .trimmed(.whitespace)
            .makeString()
    }

    mutating func extractSection(opensWith opener: Byte, closesWith closer: Byte) throws -> Bytes {
        
        guard current ==  opener else {
            let have = current.flatMap { [$0] }?.makeString()
            throw ParseError.missingBodyOpener(
                expected: [opener].makeString(),
                have: have,
                line: line,
                column: column
            )
        }

        var subBodies = 0
        var body = Bytes()
        /*
            // TODO: ignore found tokens _inside_ of a tag.
        */
        while let value = moveForward() {
            // TODO: Account for escaping `\`
            if value == closer && subBodies == 0 { break }
            if value == opener { subBodies += 1 }
            if value == closer { subBodies -= 1 }
            body.append(value)
        }

        guard current == closer else {
            throw ParseError.missingBodyCloser(
                expected: [closer].makeString(),
                line: line,
                column: column
            )
        }

        return body
    }
}

extension Sequence where Iterator.Element == Byte {
    func extractParameters() throws -> [Parameter] {
        let parser = ParameterParser(self.array)
        return try parser.process()
    }
}

import Core

fileprivate final class ParameterParser {
    var buffer: Buffer

    init(_ bytes: Bytes) {
        buffer = Buffer(bytes: bytes)
    }

    func process() throws -> [Parameter] {
        var params = [Parameter]()
        while let next = try nextParameter() {
            params.append(next)
        }
        return params
    }

    private func nextParameter() throws -> Parameter? {
        try buffer.skipWhitespace()

        guard try !buffer.next(matchesAny: .rightParenthesis) else { return nil }
        guard let next = try buffer.next() else { return nil }
        guard next != .comma else { return try nextParameter() }
        buffer.returnToBuffer(next)

        if next == .quote {
            return try nextConstant()
        } else if next == .colon {
            // Most people shouldn't need a leading colon, it's only to disambiguate expressions w/ quotes, ie: #if(:"1" == "1")
            return try nextExpression()
        } else {
            return try nextVariableOrExpression()
        }
    }

    private func nextVariableOrExpression() throws -> Parameter {
        let collected = try buffer.collect(until: .comma, .rightParenthesis).trimmed(.whitespace)
        // discard `,` or ')'
        try buffer.discardNext(1)
        try buffer.skipWhitespace()

        // space identifies
        if collected.contains(.space) {
            let components = collected
                .split(separator: .space, omittingEmptySubsequences: true)
                .map { $0.makeString() }
            return .expression(components: components)
        } else {
            let variable = collected
                .makeString()
                .components(separatedBy: ".")
            return .variable(path: variable)
        }
    }

    private func nextExpression() throws -> Parameter {
        // clear disambiguator ':'
        try buffer.discardNext(1)

        let collected = try buffer.collect(until: .comma, .rightParenthesis).trimmed(.whitespace)
        // discard `,` or ')'
        try buffer.discardNext(1)
        try buffer.skipWhitespace()

        let components = collected
            .split(separator: .space, omittingEmptySubsequences: true)
            .map { $0.makeString() }
        return .expression(components: components)
    }

    private func nextConstant() throws -> Parameter {
        // discard leading `"`
        try buffer.discardNext(1)

        var collected = Bytes()
        while let next = try buffer.next() {
            if next == .quote, buffer.previous != .backSlash {
                break
            }
            collected.append(next)
        }

        return .constant(value: collected.makeString())
    }
}


extension ParameterParser {
    fileprivate final class Buffer: StaticDataBuffer {
        var previous: Byte? = nil
        var current: Byte? = nil

        override init<B: Sequence>(bytes: B) where B.Iterator.Element == Byte {
            super.init(bytes: bytes)
        }

        override func next() throws -> Byte? {
            let n = try super.next()
            previous = current
            current = n
            return n
        }

        func skipWhitespace() throws {
            while try next(matches: Bytes.whitespace.contains) {
                try discardNext(1)
            }
        }
    }
}
