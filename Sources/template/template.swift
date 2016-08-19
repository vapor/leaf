/*
     // TODO: GLOBAL
     - Filters/Modifiers are supported longform, consider implementing short form -> Possibly compile out to longform
         `@(foo.bar()` == `@bar(foo)`
         `@(foo.bar().waa())` == `@bar(foo) { @waa(self) }`
     - Extendible Leafs
     - Allow no argument tags to terminate with a space, ie: @h1 {` or `@date`
     - HTML Tags, a la @h1() { }
*/
import Core
import Foundation

var workDir: String {
    let parent = #file.characters.split(separator: "/").map(String.init).dropLast().joined(separator: "/")
    let path = "/\(parent)/../../Resources/"
    return path
}

func loadLeaf(named name: String) throws -> Leaf {
    let stem = Stem()
    let template = try stem.loadLeaf(named: name)
    return template
}

func load(path: String) throws -> Bytes {
    guard let data = NSData(contentsOfFile: path) else {
        throw "unable to load bytes"
    }
    var bytes = Bytes(repeating: 0, count: data.length)
    data.getBytes(&bytes, length: bytes.count)
    return bytes
}

public enum Parameter {
    case variable(String)
    case constant(String)
}

extension Leaf {
    public enum Component {
        case raw(Bytes)
        case tagTemplate(TagTemplate)
        case chain([TagTemplate])
    }
}

enum Argument {
    case variable(key: String, value: Any?)
    case constant(value: String)
}

// TODO: Should optional be renderable, and render underlying?
protocol Renderable {
    func rendered() throws -> Bytes
}

extension Stem {
    func loadLeaf(raw: String) throws -> Leaf {
        return try loadLeaf(raw: raw.bytes)
    }

    func loadLeaf(raw: Bytes) throws -> Leaf {
        let raw = raw.trimmed(.whitespace)
        var buffer = Buffer(raw)
        let components = try buffer.components().map(postcompile)
        let template = Leaf(raw: raw.string, components: components)
        return template
    }

    func loadLeaf(named name: String) throws -> Leaf {
        var subpath = name.finished(with: SUFFIX)
        if subpath.hasPrefix("/") {
            subpath = String(subpath.characters.dropFirst())
        }
        let path = workingDirectory + subpath

        let raw = try load(path: path)
        return try loadLeaf(raw: raw)
    }

    private func postcompile(_ component: Leaf.Component) throws -> Leaf.Component {
        func commandPostcompile(_ tagTemplate: TagTemplate) throws -> TagTemplate {
            guard let command = tags[tagTemplate.name] else { throw "unsupported tagTemplate: \(tagTemplate.name)" }
            return try command.postCompile(stem: self,
                                           tagTemplate: tagTemplate)
        }

        switch component {
        case .raw(_):
            return component
        case let .tagTemplate(tagTemplate):
            let updated = try commandPostcompile(tagTemplate)
            return .tagTemplate(updated)
        case let .chain(tagTemplates):
            let mapped = try tagTemplates.map(commandPostcompile)
            return .chain(mapped)
        }
    }
}

extension TagTemplate {
    func makeArguments(filler: Scope) -> [Argument] {
        var input = [Argument]()
        parameters.forEach { arg in
            switch arg {
            case let .variable(key):
                let value = filler.get(path: key)
                input.append(.variable(key: key, value: value))
            case let .constant(c):
                input.append(.constant(value: c))
            }
        }
        return input
    }
}
extension Leaf: CustomStringConvertible {
    public var description: String {
        let components = self.components.map { $0.description } .joined(separator: ", ")
        return "Leaf: " + components
    }
}

extension Leaf.Component: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .raw(r):
            return ".raw(\(r.string))"
        case let .tagTemplate(i):
            return ".tagTemplate(\(i))"
        case let .chain(chain):
            return ".chain(\(chain))"
        }
    }
}

extension TagTemplate: CustomStringConvertible {
    public var description: String {
        return "(name: \(name), parameters: \(parameters), body: \(body)"
    }
}

extension Parameter: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .variable(v):
            return ".variable(\(v))"
        case let .constant(c):
            return ".constant(\(c))"
        }
    }
}

extension Leaf.Component: Equatable {}
public func == (lhs: Leaf.Component, rhs: Leaf.Component) -> Bool {
    switch (lhs, rhs) {
    case let (.raw(l), .raw(r)):
        return l == r
    case let (.tagTemplate(l), .tagTemplate(r)):
        return l == r
    default:
        return false
    }
}

extension Leaf: Equatable {}
public func == (lhs: Leaf, rhs: Leaf) -> Bool {
    return lhs.components == rhs.components
}

extension TagTemplate: Equatable {}
public func == (lhs: TagTemplate, rhs: TagTemplate) -> Bool {
    return lhs.name == rhs.name
        && lhs.parameters == rhs.parameters
        && lhs.body == rhs.body
}

extension Parameter: Equatable {}
public func == (lhs: Parameter, rhs: Parameter) -> Bool {
    switch (lhs, rhs) {
    case let (.variable(l), .variable(r)):
        return l == r
    case let (.constant(l), .constant(r)):
        return l == r
    default:
        return false
    }
}

extension Parameter {
    init<S: Sequence where S.Iterator.Element == Byte>(_ bytes: S) throws {
        let bytes = bytes.array.trimmed(.whitespace)
        guard !bytes.isEmpty else { throw "invalid argument: empty" }
        if bytes.first == .quotationMark {
            guard bytes.count > 1 && bytes.last == .quotationMark else { throw "invalid argument: missing-trailing-quotation" }
            self = .constant(bytes.dropFirst().dropLast().string)
        } else {
            self = .variable(bytes.string)
        }
    }
}

extension Scope {
    func rendered(path: String) throws -> Bytes? {
        guard let value = self.get(path: path) else { return nil }
        guard let renderable = value as? Renderable else {
            let made = "\(value)".bytes
            print("Made: \(made.string)")
            print("")
            return made
        }
        return try renderable.rendered()
    }
}

let Default = Stem()

extension Leaf {
    func render(in stem: Stem, with filler: Scope) throws -> Bytes {
        let initialQueue = filler.queue
        defer { filler.queue = initialQueue }

        var buffer = Bytes()
        try components.forEach { component in
            switch component {
            case let .raw(bytes):
                buffer += bytes
            case let .tagTemplate(tagTemplate):
                guard let command = stem.tags[tagTemplate.name] else { throw "unsupported tagTemplate" }
                let arguments = try command.makeArguments(
                    stem: stem,
                    filler: filler,
                    tagTemplate: tagTemplate
                )

                let value = try command.run(stem: stem, filler: filler, tagTemplate: tagTemplate, arguments: arguments)
                let shouldRender = command.shouldRender(
                    stem: stem,
                    filler: filler,
                    tagTemplate: tagTemplate,
                    arguments: arguments,
                    value: value
                )
                guard shouldRender else { return }

                switch value {
                    //case let fuzzy as FuzzyAccessible:
                //filler.push(fuzzy)
                case let val?: // unwrap if possible to remove from printing
                    filler.push(["self": val])
                default:
                    filler.push(["self": value])
                }

                if let subtemplate = tagTemplate.body {
                    buffer += try command.render(stem: stem, filler: filler, value: value, template: subtemplate)
                } else if let rendered = try filler.rendered(path: "self") {
                    buffer += rendered
                }
            case let .chain(chain):
                /**
                 *********************
                 ****** WARNING ******
                 *********************
                 
                 Deceptively similar to above, nuance will break e'rything!
                 **/
                print("Chain: \n\(chain.map { "\($0)" } .joined(separator: "\n"))")
                for tagTemplate in chain {
                    // TODO: Copy pasta, clean up
                    guard let command = stem.tags[tagTemplate.name] else { throw "unsupported tagTemplate" }
                    let arguments = try command.makeArguments(
                        stem: stem,
                        filler: filler,
                        tagTemplate: tagTemplate
                    )

                    let value = try command.run(stem: stem, filler: filler, tagTemplate: tagTemplate, arguments: arguments)
                    let shouldRender = command.shouldRender(
                        stem: stem,
                        filler: filler,
                        tagTemplate: tagTemplate,
                        arguments: arguments,
                        value: value
                    )
                    guard shouldRender else {
                        // ** WARNING **//
                        continue
                    }

                    switch value {
                        //case let fuzzy as FuzzyAccessible:
                    //filler.push(fuzzy)
                    case let val?:
                        filler.push(["self": val])
                    default:
                        filler.push(["self": value])
                    }

                    if let subtemplate = tagTemplate.body {
                        buffer += try command.render(stem: stem, filler: filler, value: value, template: subtemplate)
                    } else if let rendered = try filler.rendered(path: "self") {
                        buffer += rendered
                    }

                    // NECESSARY TO POP!
                    filler.pop()
                    return // Once a link in the chain is marked as pass (shouldRender), break scope
                }
            }
        }
        return buffer
    }

/*
    func _render(with filler: Scope) throws -> Bytes {
        let initialQueue = filler.queue
        defer { filler.queue = initialQueue }

        var buffer = Bytes()
        try components.forEach { component in
            switch component {
            case let .raw(bytes):
                buffer += bytes
            case let .tagTemplate(tagTemplate):
                guard let command = tags[tagTemplate.name] else { throw "unsupported tagTemplate" }

                let arguments = try command.preprocess(tagTemplate: tagTemplate, with: filler)
                print(arguments)
                let shouldRender = try command.process(
                    arguments: arguments,
                    with: filler
                )
                print(shouldRender)
                guard shouldRender else { return }
                let template = try command.prerender(
                    tagTemplate: tagTemplate,
                    arguments: arguments,
                    with: filler
                )
                if let template = template {
                    buffer += try command.render(template: template, with: filler)
                } else if let rendered = try filler.rendered(path: "self") {
                    buffer += rendered
                }
            case let .chain(chain):
                for tagTemplate in chain {
                    guard let command = tags[tagTemplate.name] else { throw "unsupported tagTemplate" }
                    let arguments = try command.preprocess(tagTemplate: tagTemplate, with: filler)
                    let shouldRender = try command.process(arguments: arguments, with: filler)
                    guard shouldRender else { continue }
                    if let template = tagTemplate.body {
                        buffer += try command.render(template: template, with: filler)
                    } else if let rendered = try filler.rendered(path: "self") {
                        buffer += rendered
                    }
                    return // Once a link in the chain is marked as pass (shouldRender), break scope
                }
            }
        }
        return buffer
    }
 */
}

extension Leaf.Component {
    mutating func addToChain(_ chainedInstruction: TagTemplate) throws {
        switch self {
        case .raw(_):
            throw "unable to chain \(chainedInstruction) w/o preceding tagTemplate"
        case let .tagTemplate(current):
            self = .chain([current, chainedInstruction])
        case let .chain(chain):
            self = .chain(chain + [chainedInstruction])
        }
    }
}
