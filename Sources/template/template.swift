/*
     // TODO: GLOBAL
     - Filters/Modifiers are supported longform, consider implementing short form -> Possibly compile out to longform
         `@(foo.bar()` == `@bar(foo)`
         `@(foo.bar().waa())` == `@bar(foo) { @waa(self) }`
     - Extendible Leafs
*/
import Core
import Foundation

var workDir: String {
    let parent = #file.characters.split(separator: "/").map(String.init).dropLast().joined(separator: "/")
    let path = "/\(parent)/../../Resources/"
    return path
}

func loadLeaf(named name: String) throws -> Leaf {
    let namespace = NameSpace()
    let template = try namespace.loadLeaf(named: name)
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


protocol BufferProtocol {
    associatedtype Element
    var previous: Element? { get }
    var current: Element? { get }
    var next: Element? { get }

    @discardableResult
    mutating func moveForward() -> Element?
}

struct Buffer<T>: BufferProtocol {
    typealias Element = T

    private(set) var previous: T? = nil
    private(set) var current: T? = nil
    private(set) var next: T? = nil

    private var buffer: IndexingIterator<[T]>

    init<S: Sequence where S.Iterator.Element == T>(_ sequence: S) {
        buffer = sequence.array.makeIterator()
        // queue up first
        moveForward() // sets next
        moveForward() // sets current
    }

    @discardableResult
    mutating func moveForward() -> T? {
        previous = current
        current = next
        next = buffer.next()
        return current
    }
}

extension Byte {
    static let openParenthesis = "(".bytes.first!
    static let closedParenthesis = ")".bytes.first!
    static let openCurly = "{".bytes.first!
    static let closedCurly = "}".bytes.first!
}

extension BufferProtocol where Element == Byte {
    mutating func components() throws -> [Leaf.Component] {
        var comps: [Leaf.Component] = []
        while let next = try nextComponent() {
            print("Got component: \(next)")
            print("")
            if case let .instruction(i) = next, i.isChain {
                guard comps.count > 0 else { throw "invalid chain component w/o preceeding instruction" }
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
            let instruction = try extractInstruction()
            return .instruction(instruction)
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
    mutating func extractInstruction() throws -> Leaf.Component.Instruction {
        let name = try extractInstructionName()
        print("Got name: \(name)")
        let parameters = try extractInstructionParameters()

        // check if body
        moveForward()
        guard current == .space, next == .openCurly else {
            return try Leaf.Component.Instruction(name: name, parameters: parameters, body: String?.none)
        }
        moveForward() // queue up `{`

        // TODO: Body should be template components
        let body = try extractBody()
        moveForward()
        return try Leaf.Component.Instruction(name: name, parameters: parameters, body: body)
    }

    mutating func extractInstructionName() throws -> String {
        // can't extract section because of @@
        guard current == TOKEN else { throw "instruction name must lead with token" }
        moveForward() // drop initial token from name. a secondary token implies chain
        let name = extractUntil { $0 == .openParenthesis }
        guard current == .openParenthesis else { throw "instruction names must be alphanumeric and terminated with '('" }
        return name.string
    }

    mutating func extractInstructionParameters() throws -> [Leaf.Component.Instruction.Parameter] {
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

extension Byte {
    static let quotationMark = "\"".bytes.first!
}

extension Sequence where Iterator.Element == Byte {
    func extractParameters() throws -> [Leaf.Component.Instruction.Parameter] {
        return try split(separator: .comma)
            .map { try Leaf.Component.Instruction.Parameter.init($0) }
    }
}

extension Sequence where Iterator.Element == Byte {
    static var whitespace: Bytes {
        return [ .space, .newLine, .carriageReturn, .horizontalTab]
    }
}


final class Leaf {
    // TODO: Bytes?
    // reference only
    let raw: String
    let components: [Component]

    init(raw: String, components: [Component]) {
        self.raw = raw
        self.components = components
    }

    init(raw: String) throws {
        self.raw = raw
        var buffer = Buffer(raw.bytes.trimmed(.whitespace).array)
        self.components = try buffer.components()
    }
}

extension Leaf {
    enum Component {
        final class Instruction {
            enum Parameter {
                case variable(String)
                case constant(String)
            }

            let name: String
            let parameters: [Parameter]

            let body: Leaf?

            fileprivate var isChain: Bool

            convenience init(name: String, parameters: [Parameter], body: String?) throws {
                let body = try body.flatMap { try Leaf(raw: $0) }
                self.init(name: name, parameters: parameters, body: body)
            }


            init(name: String, parameters: [Parameter], body: Leaf?) {
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

        case raw(Bytes)
        case instruction(Instruction)
        case chain([Instruction])
    }
}

enum Argument {
    case variable(key: String, value: Any?)
    case constant(value: String)
}

protocol Renderable {
    func rendered() throws -> Bytes
}

protocol InstructionDriver {
    var name: String { get }

    // after a template is compiled, an instruction will be passed in for validation/modification if necessary
    func postCompile(namespace: NameSpace,
                     instruction: Leaf.Component.Instruction) throws -> Leaf.Component.Instruction

    // turn parameters in instruction into concrete arguments
    func makeArguments(namespace: NameSpace,
                       filler: Filler,
                       instruction: Instruction) throws -> [Argument]


    // run the driver w/ the specified arguments and returns the value to add to scope or render
    func run(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument]) throws -> Any?

    // whether or not the given value should be rendered. Defaults to `!= nil`
    func shouldRender(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument], value: Any?) -> Bool

    // filler is populated with value at this point
    // renders a given template, can override for custom behavior. For example, #loop
    func render(namespace: NameSpace, filler: Filler, value: Any?, template: Leaf) throws -> Bytes
}

extension InstructionDriver {
    func postCompile(namespace: NameSpace,
                     instruction: Leaf.Component.Instruction) throws -> Leaf.Component.Instruction {
        return instruction
    }

    func makeArguments(namespace: NameSpace,
                       filler: Filler,
                       instruction: Instruction) throws -> [Argument]{
        return instruction.makeArguments(filler: filler)
    }

    func run(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument]) throws -> Any? {
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

    func shouldRender(namespace: NameSpace,
                      filler: Filler,
                      instruction: Instruction,
                      arguments: [Argument],
                      value: Any?) -> Bool {
        return value != nil
    }

    func render(namespace: NameSpace,
                filler: Filler,
                value: Any?,
                template: Leaf) throws -> Bytes {
        return try template.render(in: namespace, with: filler)
    }
}


typealias Instruction = Leaf.Component.Instruction

class NameSpace {
    let workingDirectory: String
    var drivers: [String: InstructionDriver] = [
        "": _Variable(),
        "if": _If(),
        "else": _Else(),
        "loop": _Loop(),
        "uppercased": _Uppercased(),
        "include": _Include()
    ]

    init(workingDirectory: String = workDir) {
        self.workingDirectory = workingDirectory.finished(with: "/")
    }
}

extension NameSpace {
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
        func commandPostcompile(_ instruction: Leaf.Component.Instruction) throws -> Leaf.Component.Instruction {
            guard let command = drivers[instruction.name] else { throw "unsupported instruction: \(instruction.name)" }
            return try command.postCompile(namespace: self,
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

extension Instruction {
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

final class _Include: InstructionDriver {
    let name = "include"

    // TODO: Use
    var cache: [String: Leaf] = [:]

    func postCompile(
        namespace: NameSpace,
        instruction: Leaf.Component.Instruction) throws -> Leaf.Component.Instruction {
        guard instruction.parameters.count == 1 else { throw "invalid include" }
        switch instruction.parameters[0] {
        case let .constant(name): // ok to be subpath, NOT ok to b absolute
            let body = try namespace.loadLeaf(named: name)
            return Leaf.Component.Instruction(
                name: instruction.name,
                parameters: [], // no longer need parameters
                body: body
            )
        case let .variable(name):
            throw "include's must not be dynamic, try `@include(\"\(name)\")"
        }
    }

    func run(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument]) throws -> Any? {
        return nil
    }

    func shouldRender(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument], value: Any?) -> Bool {
        // throws at precompile, should always render
        return true
    }
}

final class _Loop: InstructionDriver {
    let name = "loop"

    func run(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument]) throws -> Any? {
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

    func render(namespace: NameSpace, filler: Filler, value: Any?, template: Leaf) throws -> Bytes {
        guard let array = value as? [Any] else { fatalError() }

        // return try array.map { try template.render(with: $0) } .flatMap { $0 + [.newLine] }
        return try array
            .map { item -> Bytes in
                if let i = item as? FuzzyAccessible {
                    filler.push(i)
                } else {
                    filler.push(["self": item])
                }

                let rendered = try template.render(in: namespace, with: filler)

                filler.pop()

                return rendered
            }
            .flatMap { $0 + [.newLine] }
    }
}

final class _Uppercased: InstructionDriver {

    let name = "uppercased"

    func run(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument]) throws -> Any? {
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

final class _Else: InstructionDriver {
    let name = "else"
    func run(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument]) throws -> Any? {
        return nil
    }
    func shouldRender(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument], value: Any?) -> Bool {
        return true
    }
}

final class _If: InstructionDriver {
    let name = "if"

    func run(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument]) throws -> Any? {
        guard arguments.count == 1 else { throw "invalid if statement arguments" }
        return nil
    }

    func shouldRender(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument], value: Any?) -> Bool {
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

final class _Variable: InstructionDriver {
    let name = "" // empty name, ie: @(variable)

    func run(namespace: NameSpace, filler: Filler, instruction: Instruction, arguments: [Argument]) throws -> Any? {
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
    var description: String {
        let components = self.components.map { $0.description } .joined(separator: ", ")
        return "Leaf: " + components
    }
}

extension Leaf.Component: CustomStringConvertible {
    var description: String {
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

extension Leaf.Component.Instruction: CustomStringConvertible {
    var description: String {
        return "(name: \(name), parameters: \(parameters), body: \(body)"
    }
}

extension Leaf.Component.Instruction.Parameter: CustomStringConvertible {
    var description: String {
        switch self {
        case let .variable(v):
            return ".variable(\(v))"
        case let .constant(c):
            return ".constant(\(c))"
        }
    }
}

extension Leaf.Component: Equatable {}
func == (lhs: Leaf.Component, rhs: Leaf.Component) -> Bool {
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
func == (lhs: Leaf, rhs: Leaf) -> Bool {
    return lhs.components == rhs.components
}

extension Leaf.Component.Instruction: Equatable {}
func == (lhs: Leaf.Component.Instruction, rhs: Leaf.Component.Instruction) -> Bool {
    return lhs.name == rhs.name
        && lhs.parameters == rhs.parameters
        && lhs.body == rhs.body
}

extension Leaf.Component.Instruction.Parameter: Equatable {}
func == (lhs: Leaf.Component.Instruction.Parameter, rhs: Leaf.Component.Instruction.Parameter) -> Bool {
    switch (lhs, rhs) {
    case let (.variable(l), .variable(r)):
        return l == r
    case let (.constant(l), .constant(r)):
        return l == r
    default:
        return false
    }
}

extension Leaf.Component.Instruction.Parameter {
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

let Default = NameSpace()

extension Leaf {
    func render(in namespace: NameSpace, with filler: Filler) throws -> Bytes {
        let initialQueue = filler.queue
        defer { filler.queue = initialQueue }

        var buffer = Bytes()
        try components.forEach { component in
            switch component {
            case let .raw(bytes):
                buffer += bytes
            case let .instruction(instruction):
                guard let command = namespace.drivers[instruction.name] else { throw "unsupported instruction" }
                let arguments = try command.makeArguments(
                    namespace: namespace,
                    filler: filler,
                    instruction: instruction
                )

                let value = try command.run(namespace: namespace, filler: filler, instruction: instruction, arguments: arguments)
                let shouldRender = command.shouldRender(
                    namespace: namespace,
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
                    buffer += try command.render(namespace: namespace, filler: filler, value: value, template: subtemplate)
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
                    guard let command = namespace.drivers[instruction.name] else { throw "unsupported instruction" }
                    let arguments = try command.makeArguments(
                        namespace: namespace,
                        filler: filler,
                        instruction: instruction
                    )

                    let value = try command.run(namespace: namespace, filler: filler, instruction: instruction, arguments: arguments)
                    let shouldRender = command.shouldRender(
                        namespace: namespace,
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
                        buffer += try command.render(namespace: namespace, filler: filler, value: value, template: subtemplate)
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
                guard let command = drivers[instruction.name] else { throw "unsupported instruction" }

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
                    guard let command = drivers[instruction.name] else { throw "unsupported instruction" }
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
    mutating func addToChain(_ chainedInstruction: Instruction) throws {
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
