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


/*
    Potentially expose in future
*/
let TOKEN: Byte = .numberSign
let SUFFIX = ".leaf"

final class Filler {

    let workingDirectory: String = "./"

    private(set) var queue: [FuzzyAccessible]

    init(_ fuzzy: FuzzyAccessible) {
        self.queue = [fuzzy]
    }

    func get(key: String) -> Any? {
        return queue.lazy.reversed().flatMap { $0.get(key: key) } .first
    }

    func get(path: String) -> Any? {
        let components = path.components(separatedBy: ".")
        return queue.lazy.reversed().flatMap { next in
            print("Next: [\(next.dynamicType)]:\(next)")
            let value = next.get(path: components)
            print("Value: \(value)")
            return value
            // $0.get(path: path)
            }
            .first
    }

    public func get(path: [String]) -> Any? {
        let first: Optional<Any> = self
        return path.reduce(first) { next, index in
            guard let next = next as? FuzzyAccessible else { return nil }
            return next.get(key: index)
        }
    }

    func push(_ fuzzy: FuzzyAccessible) {
        queue.append(fuzzy)
    }

    @discardableResult
    func pop() -> FuzzyAccessible? {
        guard !queue.isEmpty else { return nil }
        return queue.removeLast()
    }
}

extension String: Swift.Error {}


extension Byte {
    var isLeafToken: Bool {
        return self == TOKEN
    }
}

extension Byte {
    static let openParenthesis = "(".bytes.first!
    static let closedParenthesis = ")".bytes.first!
    static let openCurly = "{".bytes.first!
    static let closedCurly = "}".bytes.first!
}

extension Byte {
    static let quotationMark = "\"".bytes.first!
}

extension Sequence where Iterator.Element == Byte {
    static var whitespace: Bytes {
        return [ .space, .newLine, .carriageReturn, .horizontalTab]
    }
}

public enum Parameter {
    case variable(String)
    case constant(String)
}

public final class TagTemplate {
    public let name: String
    public let parameters: [Parameter]

    public let body: Leaf?

    internal let isChain: Bool

    internal convenience init(name: String, parameters: [Parameter], body: String?) throws {
        let body = try body.flatMap { try Leaf(raw: $0) }
        self.init(name: name, parameters: parameters, body: body)
    }


    internal init(name: String, parameters: [Parameter], body: Leaf?) {
        // we strip leading token, if another one is there,
        // that means we've found a chain element, ie: @@else {
        if name.bytes.first == TOKEN {
            self.isChain = true
            self.name = name.bytes.dropFirst().string
        } else {
            self.isChain = false
            self.name = name
        }

        self.parameters = parameters
        self.body = body
    }
}

extension Leaf {
    public enum Component {
        case raw(Bytes)
        case instruction(TagTemplate)
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


protocol Tag {
    var name: String { get }

    // after a template is compiled, an instruction will be passed in for validation/modification if necessary
    func postCompile(stem: Stem,
                     instruction: TagTemplate) throws -> TagTemplate

    // turn parameters in instruction into concrete arguments
    func makeArguments(stem: Stem,
                       filler: Filler,
                       instruction: TagTemplate) throws -> [Argument]


    // run the tag w/ the specified arguments and returns the value to add to scope or render
    func run(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument]) throws -> Any?

    // whether or not the given value should be rendered. Defaults to `!= nil`
    func shouldRender(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument], value: Any?) -> Bool

    // filler is populated with value at this point
    // renders a given template, can override for custom behavior. For example, #loop
    func render(stem: Stem, filler: Filler, value: Any?, template: Leaf) throws -> Bytes
}

extension Tag {
    func postCompile(stem: Stem,
                     instruction: TagTemplate) throws -> TagTemplate {
        return instruction
    }

    func makeArguments(stem: Stem,
                       filler: Filler,
                       instruction: TagTemplate) throws -> [Argument]{
        return instruction.makeArguments(filler: filler)
    }

    func run(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument]) throws -> Any? {
        guard arguments.count == 1 else {
            throw "more than one argument not supported, override \(#function) for custom behavior"
        }

        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            return value
        case let .variable(key: _, value: value):
            return value
        }
    }

    func shouldRender(stem: Stem,
                      filler: Filler,
                      instruction: TagTemplate,
                      arguments: [Argument],
                      value: Any?) -> Bool {
        return value != nil
    }

    func render(stem: Stem,
                filler: Filler,
                value: Any?,
                template: Leaf) throws -> Bytes {
        return try template.render(in: stem, with: filler)
    }
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
        func commandPostcompile(_ instruction: TagTemplate) throws -> TagTemplate {
            guard let command = tags[instruction.name] else { throw "unsupported instruction: \(instruction.name)" }
            return try command.postCompile(stem: self,
                                           instruction: instruction)
        }

        switch component {
        case .raw(_):
            return component
        case let .instruction(instruction):
            let updated = try commandPostcompile(instruction)
            return .instruction(updated)
        case let .chain(instructions):
            let mapped = try instructions.map(commandPostcompile)
            return .chain(mapped)
        }
    }
}

extension TagTemplate {
    func makeArguments(filler: Filler) -> [Argument] {
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

final class _Include: Tag {
    let name = "include"

    // TODO: Use
    var cache: [String: Leaf] = [:]

    func postCompile(
        stem: Stem,
        instruction: TagTemplate) throws -> TagTemplate {
        guard instruction.parameters.count == 1 else { throw "invalid include" }
        switch instruction.parameters[0] {
        case let .constant(name): // ok to be subpath, NOT ok to b absolute
            let body = try stem.loadLeaf(named: name)
            return TagTemplate(
                name: instruction.name,
                parameters: [], // no longer need parameters
                body: body
            )
        case let .variable(name):
            throw "include's must not be dynamic, try `@include(\"\(name)\")"
        }
    }

    func run(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument]) throws -> Any? {
        return nil
    }

    func shouldRender(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument], value: Any?) -> Bool {
        // throws at precompile, should always render
        return true
    }
}

final class _Loop: Tag {
    let name = "loop"

    func run(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument]) throws -> Any? {
        guard arguments.count == 2 else {
            throw "loop requires two arguments, var w/ array, and constant w/ sub name"
        }

        switch (arguments[0], arguments[1]) {
        case let (.variable(key: _, value: value?), .constant(value: innername)):
            let array = value as? [Any] ?? [value]
            return array.map { [innername: $0] }
        // return true
        default:
            return nil
            // return false
        }
    }

    func render(stem: Stem, filler: Filler, value: Any?, template: Leaf) throws -> Bytes {
        guard let array = value as? [Any] else { fatalError() }

        // return try array.map { try template.render(with: $0) } .flatMap { $0 + [.newLine] }
        return try array
            .map { item -> Bytes in
                if let i = item as? FuzzyAccessible {
                    filler.push(i)
                } else {
                    filler.push(["self": item])
                }

                let rendered = try template.render(in: stem, with: filler)

                filler.pop()

                return rendered
            }
            .flatMap { $0 + [.newLine] }
    }
}

final class _Uppercased: Tag {

    let name = "uppercased"

    func run(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument]) throws -> Any? {
        guard arguments.count == 1 else { throw "\(self) only accepts single arguments" }
        switch arguments[0] {
        case let .constant(value: value):
            return value.uppercased()
        case let .variable(key: _, value: value as String):
            return value.uppercased()
        case let .variable(key: _, value: value as Renderable):
            return try value.rendered().string.uppercased()
        case let .variable(key: _, value: value?):
            return "\(value)".uppercased()
        default:
            return nil
        }
    }

    func process(arguments: [Argument], with filler: Filler) throws -> Bool {
        guard arguments.count == 1 else { throw "uppercase only accepts single arguments" }
        switch arguments[0] {
        case let .constant(value: value):
            filler.push(["self": value.uppercased()])
        case let .variable(key: _, value: value as String):
            filler.push(["self": value.uppercased()])
        case let .variable(key: _, value: value as Renderable):
            let uppercased = try value.rendered().string.uppercased()
            filler.push(["self": uppercased])
        case let .variable(key: _, value: value?):
            filler.push(["self": "\(value)".uppercased()])
        default:
            return false
        }

        return true
    }
}

final class _Else: Tag {
    let name = "else"
    func run(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument]) throws -> Any? {
        return nil
    }
    func shouldRender(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument], value: Any?) -> Bool {
        return true
    }
}

final class _If: Tag {
    let name = "if"

    func run(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument]) throws -> Any? {
        guard arguments.count == 1 else { throw "invalid if statement arguments" }
        return nil
    }

    func shouldRender(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument], value: Any?) -> Bool {
        guard arguments.count == 1 else { return false }
        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            let bool = Bool(value)
            return bool == true
        case let .variable(key: _, value: value as Bool):
            return value
        case let .variable(key: _, value: value as String):
            let bool = Bool(value)
            return bool == true
        case let .variable(key: _, value: value as Int):
            return value == 1
        case let .variable(key: _, value: value as Double):
            return value == 1.0
        case let .variable(key: _, value: value):
            return value != nil
        }
    }
}

final class _Variable: Tag {
    let name = "" // empty name, ie: @(variable)

    func run(stem: Stem, filler: Filler, instruction: TagTemplate, arguments: [Argument]) throws -> Any? {
        /*
         Currently ALL '@' signs are interpreted as instructions.  This means to escape in

         name@email.com

         We'd have to do:

         name@("@")email.com

         or more pretty

         contact-email@("@email.com")

         By having this uncommented, we could allow

         name@()email.com
         */
        if arguments.isEmpty { return [TOKEN].string } // temporary escaping mechanism?
        guard arguments.count == 1 else { throw "invalid var argument" }
        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            return value
        case let .variable(key: _, value: value):
            return value
        }
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
        case let .instruction(i):
            return ".instruction(\(i))"
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
    case let (.instruction(l), .instruction(r)):
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

extension Filler {
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
    func render(in stem: Stem, with filler: Filler) throws -> Bytes {
        let initialQueue = filler.queue
        defer { filler.queue = initialQueue }

        var buffer = Bytes()
        try components.forEach { component in
            switch component {
            case let .raw(bytes):
                buffer += bytes
            case let .instruction(instruction):
                guard let command = stem.tags[instruction.name] else { throw "unsupported instruction" }
                let arguments = try command.makeArguments(
                    stem: stem,
                    filler: filler,
                    instruction: instruction
                )

                let value = try command.run(stem: stem, filler: filler, instruction: instruction, arguments: arguments)
                let shouldRender = command.shouldRender(
                    stem: stem,
                    filler: filler,
                    instruction: instruction,
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

                if let subtemplate = instruction.body {
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
                for instruction in chain {
                    // TODO: Copy pasta, clean up
                    guard let command = stem.tags[instruction.name] else { throw "unsupported instruction" }
                    let arguments = try command.makeArguments(
                        stem: stem,
                        filler: filler,
                        instruction: instruction
                    )

                    let value = try command.run(stem: stem, filler: filler, instruction: instruction, arguments: arguments)
                    let shouldRender = command.shouldRender(
                        stem: stem,
                        filler: filler,
                        instruction: instruction,
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

                    if let subtemplate = instruction.body {
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
    func _render(with filler: Filler) throws -> Bytes {
        let initialQueue = filler.queue
        defer { filler.queue = initialQueue }

        var buffer = Bytes()
        try components.forEach { component in
            switch component {
            case let .raw(bytes):
                buffer += bytes
            case let .instruction(instruction):
                guard let command = tags[instruction.name] else { throw "unsupported instruction" }

                let arguments = try command.preprocess(instruction: instruction, with: filler)
                print(arguments)
                let shouldRender = try command.process(
                    arguments: arguments,
                    with: filler
                )
                print(shouldRender)
                guard shouldRender else { return }
                let template = try command.prerender(
                    instruction: instruction,
                    arguments: arguments,
                    with: filler
                )
                if let template = template {
                    buffer += try command.render(template: template, with: filler)
                } else if let rendered = try filler.rendered(path: "self") {
                    buffer += rendered
                }
            case let .chain(chain):
                for instruction in chain {
                    guard let command = tags[instruction.name] else { throw "unsupported instruction" }
                    let arguments = try command.preprocess(instruction: instruction, with: filler)
                    let shouldRender = try command.process(arguments: arguments, with: filler)
                    guard shouldRender else { continue }
                    if let template = instruction.body {
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
            throw "unable to chain \(chainedInstruction) w/o preceding instruction"
        case let .instruction(current):
            self = .chain([current, chainedInstruction])
        case let .chain(chain):
            self = .chain(chain + [chainedInstruction])
        }
    }
}
