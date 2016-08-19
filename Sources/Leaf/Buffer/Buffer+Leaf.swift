extension BufferProtocol where Element == Byte {
    mutating func components() throws -> [Leaf.Component] {
        var comps: [Leaf.Component] = []
        while let next = try nextComponent() {
            if case let .tagTemplate(i) = next, i.isChain {
                guard comps.count > 0 else { throw "invalid chain component w/o preceeding tagTemplate" }
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

    mutating func nextComponent() throws -> Leaf.Component? {
        guard let token = current else { return nil }
        if token == TOKEN {
            let tagTemplate = try extractInstruction()
            return .tagTemplate(tagTemplate)
        } else {
            let raw = extractUntil { $0.isLeafToken }
            return .raw(raw)
        }
    }

    mutating func extractUntil(_ until: @noescape (Element) -> Bool) -> [Element] {
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
}

/*
 Syntax
 
 @ + '<bodyName>` + `(` + `<[argument]>` + `)` + ` { ` + <body> + ` }`
 */
extension BufferProtocol where Element == Byte {
    mutating func extractInstruction() throws -> TagTemplate {
        let name = try extractInstructionName()
        let parameters = try extractInstructionParameters()

        // check if body
        moveForward()
        guard current == .space, next == .openCurly else {
            return try TagTemplate(name: name, parameters: parameters, body: String?.none)
        }
        moveForward() // queue up `{`

        // TODO: Body should be leaf components
        let body = try extractBody()
        moveForward()
        return try TagTemplate(name: name, parameters: parameters, body: body)
    }

    mutating func extractInstructionName() throws -> String {
        // can't extract section because of @@
        guard current == TOKEN else { throw "tagTemplate name must lead with token" }
        moveForward() // drop initial token from name. a secondary token implies chain
        let name = extractUntil { $0 == .openParenthesis }
        guard current == .openParenthesis else { throw "tagTemplate names must be alphanumeric and terminated with '('" }
        return name.string
    }

    mutating func extractInstructionParameters() throws -> [Parameter] {
        return try extractSection(opensWith: .openParenthesis, closesWith: .closedParenthesis)
            .extractParameters()
    }

    mutating func extractBody() throws -> String {
        return try extractSection(opensWith: .openCurly, closesWith: .closedCurly)
            .trimmed(.whitespace)
            .string
    }

    mutating func extractSection(opensWith opener: Byte, closesWith closer: Byte) throws -> Bytes {
        guard current ==  opener else {
            throw "invalid body, missing opener: \([opener].string)"
        }

        var subBodies = 0
        var body = Bytes()
        while let value = moveForward() {
            // TODO: Account for escaping `\`
            if value == closer && subBodies == 0 { break }
            if value == opener { subBodies += 1 }
            if value == closer { subBodies -= 1 }
            body.append(value)
        }

        guard current == closer else {
            throw "invalid body, missing closer: \([closer].string), got \([current])"
        }

        return body
    }
}

extension Sequence where Iterator.Element == Byte {
    func extractParameters() throws -> [Parameter] {
        return try split(separator: .comma)
            .map { try Parameter($0) }
    }
}
