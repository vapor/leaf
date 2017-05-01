extension BufferProtocol where Element == Byte {
    mutating func components(stem: Stem) throws -> [Leaf.Component] {
        var comps: [Leaf.Component] = []
        while let next = try nextComponent(stem: stem) {
            if case let .tagTemplate(i) = next, i.isChain {
                guard comps.count > 0 else {
                    throw ParseError.expectedLeadingTemplate(have: nil)
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
                        try mutable.addToChain(i)
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
        guard let token = current else { return nil }
        guard token == TOKEN else {
            let raw = extractUntil { $0 == TOKEN }
            return .raw(raw)
        }
        let tagTemplate = try extractInstruction(stem: stem)
        return .tagTemplate(tagTemplate)
    }

    mutating func extractUntil(allowsEscaping: Bool = true, _ until: (Element) -> Bool) -> [Element] {

        var collection = Bytes()
        if let current = current {
            guard !(until(current) && previous != .backSlash) else { return [] }
            collection.append(current)
        }

        while let value = moveForward(), !(until(value) && previous != .backSlash) {
            collection.append(value)
        }

        return collection
    }
}

enum ParseError: LeafError {
    case tagTemplateNotFound(name: String)
    case missingBodyOpener(expected: String, have: String?)
    case missingBodyCloser(expected: String)
    case expectedOpenParenthesis
    case expectedLeadingTemplate(have: Leaf.Component?)
}

/*
 Syntax
 
 @ + '<bodyName>` + `(` + `<[argument]>` + `)` + ` { ` + <body> + ` }`
 */
extension BufferProtocol where Element == Byte {
    mutating func extractInstruction(stem: Stem) throws -> TagTemplate {
        let name = try extractInstructionName()
        let parameters = try extractInstructionParameters()

        // check if body
        moveForward()
        guard current == .space, next == .leftCurlyBracket else {
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
            throw ParseError.expectedOpenParenthesis
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
            throw ParseError.missingBodyOpener(expected: [opener].makeString(), have: have)
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
            throw ParseError.missingBodyCloser(expected: [closer].makeString())
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
        } else {
            return try nextVariable()
        }
    }

    private func nextVariable() throws -> Parameter {
        let collected = try buffer.collect(until: .comma, .rightParenthesis)
        // discard `,` or ')'
        try buffer.discardNext(1)
        try buffer.skipWhitespace()

        let variable = collected
            .makeString()
            .components(separatedBy: ".")
        return .variable(path: variable)

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
