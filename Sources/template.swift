import Core
import Foundation

/*
public protocol PathIndexable {
    /// If self is an array representation, return array
    var pathIndexableArray: [Self]? { get }

    /// If self is an object representation, return object
    var pathIndexableObject: [String: Self]? { get }
}
*/


/*
 // TODO: GLOBAL
 
 - Context tree, so if variable isn't in lowest scope, we can search higher context
 - all instances of as? RenderContext should come with a warning for unsupported types, or take `Any`.
 */

let TOKEN: Byte = .at

extension String: Swift.Error {}

var FUNCTIONS: [String: (RenderContext) throws -> RenderContext?] = [
    "capitalized": { input in
        guard let cs = input as? CustomStringConvertible else { return nil }
        let chars = cs.description.characters
        let first = chars.first.flatMap {
            return String([$0]).uppercased()
        }
        let combo = (first ?? "") + String(chars.dropFirst().array)
        return combo
    }
]

protocol RenderContext {
    var raw: Bytes? { get }
    // var functions: [String: RenderContext] { get }
    func get(_ key: String) -> RenderContext?
}

import PathIndexable

public protocol FuzzyAccessible {
    func get(key: String) -> Any?
}

extension Dictionary: FuzzyAccessible {
    public func get(key: String) -> Any? {
        // TODO: Throw if invalid key?
        guard let key = key as? Key else { return nil }
        let value: Value? = self[key]
        return value
    }
}

extension Array: FuzzyAccessible {
    public func get(key: String) -> Any? {
        guard let idx = Int(key), idx < count else { return nil }
        return self[idx]
    }
}

extension FuzzyAccessible {
    public func get(path: String) -> Any? {
        let components = path.components(separatedBy: ".")
        return get(path: components)
    }

    public func get(path: [String]) -> Any? {
        let first: Optional<Any> = self
        return path.reduce(first) { next, index in
            guard let next = next as? FuzzyAccessible else { return nil }
            return next.get(key: index)
        }
    }
}

extension RenderContext {
    func access(_ path: PathIndex) {

    }
}

extension RenderContext {
    var functions: [String: RenderContext] { return [:] }

    var raw: Bytes? {
        guard let cs = self as? CustomStringConvertible else { return nil }
        return cs.description.bytes
    }

    func get(_ key: String) -> RenderContext? {
        guard key == "self" else { return nil }
        return self
    }
}

extension Dictionary: RenderContext {
    func get(_ key: String) -> RenderContext? {
        print("Getting in dictionary: \(self.dynamicType)")
        if key == "self" { return self }
        guard let k = key as? Key else { return nil }
        guard let value = self[k] else { return nil }
        print("Dictionary Got value type(\(value.dynamicType)): \(value)")
        let rc = value as? RenderContext
        print("Dictionary value as context: \(rc)")
        return rc
    }
}

extension Int: RenderContext {}
extension NSNumber: RenderContext {}

extension Array: RenderContext {}
extension NSArray: RenderContext {}
extension NSDictionary: RenderContext {
    func get(_ key: String) -> RenderContext? {
        return object(forKey: key) as? RenderContext
    }
}
extension Bool: RenderContext {}


extension Byte {
    var isTemplateToken: Bool {
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

enum InstructionArgument {
    case key(String)
    case value(String)
}

extension InstructionArgument: Equatable {}
func == (lhs: InstructionArgument, rhs: InstructionArgument) -> Bool {
    switch (lhs, rhs) {
    case let (.key(l), .key(r)):
        return l == r
    case let (.value(l), .value(r)):
        return l == r
    default:
        return false
    }
}

enum TemplateComponent {
    case raw(String)
    case instruction(Instruction)
    // case chain([Instruction])
}

extension String: RenderContext {}
extension String: CustomStringConvertible {
    public var description: String { return self }
}

extension NSString: RenderContext {}

protocol Command {
    var name: String { get }
    func process(arguments: [Any?]) throws -> RenderContext?
}

// TODO: Arguments self filter w/ `()`, so template: "Hello, @(name.capitalized())"
let varCommand = Var()
let COMMANDS: [String: Command] = [ varCommand.name: varCommand ]

struct Var: Command {
    let name = ""
    func process(arguments: [Any?]) throws -> RenderContext? {
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
        // if arguments.isEmpty return { "@" } // temporary escaping mechani
        guard arguments.count == 1 else { throw "invalid var argument" }
        return arguments.first as? RenderContext

        // TODO: Should variable allow body, or throw here? I think throw, but here for test
        /*
        guard let stringable = arguments.first as? CustomStringConvertible else {
            let r = arguments.first as? RenderContext
            print("not custom string convertible: \(r) first: \(arguments.first) type: \(arguments.first?.dynamicType)")
            return r
        }
        let varref = stringable.description
        print("VARREF: \(varref)")
        return varref
        */
    }
}


extension BufferProtocol where Element == Byte {
    mutating func components() throws -> [Template.Component] {
        var comps: [Template.Component] = []
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

    mutating func nextComponent() throws -> Template.Component? {
        guard let token = current else { return nil }
        if token == TOKEN {
            let instruction = try extractInstruction()
            return .instruction(instruction)
        } else {
            let raw = extractUntil { $0.isTemplateToken }
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
    mutating func extractInstruction() throws -> Template.Component.Instruction {
        let name = try extractInstructionName()
        print("Got name: \(name)")
        let parameters = try extractInstructionParameters()

        // check if body
        moveForward()
        guard current == .space, next == .openCurly else {
            return try Template.Component.Instruction(name: name, parameters: parameters, body: nil)
        }
        moveForward() // queue up `{`

        // TODO: Body should be template components
        let body = try extractBody()
        print("Extracted body: **\(body)**")
        moveForward()
        return try Template.Component.Instruction(name: name, parameters: parameters, body: body)
    }

    private func logStatus(id: Int) {
        print("\(id) PREVIOUS: \(previous.flatMap { [$0].string }) CURRENT \(current.flatMap { [$0].string }) NEXT \(next.flatMap { [$0].string })")
    }
    mutating func extractInstructionName() throws -> String {
        let ab = false
        if ab {
            let ext = try extractSection(opensWith: TOKEN, closesWith: .openParenthesis).string
            print("Got name: \(ext)")
            logStatus(id: 0)
            return ext
        } else {
            guard current == TOKEN else { throw "instruction name must lead with token" }
            moveForward() // drop initial token from name. a secondary token implies chain
            let name = extractUntil { $0 == .openParenthesis }
            logStatus(id: 0)
            print("name: \(name.string)")
            guard current == .openParenthesis else { throw "instruction names must be alphanumeric and terminated with '('" }
            return name.string
        }
    }

    mutating func extractInstructionParameters() throws -> [Template.Component.Instruction.Parameter] {
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

extension InstructionArgument {
    init(_ bytes: BytesSlice) throws {
        guard !bytes.isEmpty else { throw "invalid argument: empty" }
        if bytes.first == .quotationMark {
            guard bytes.last == .quotationMark else { throw "invalid argument: missing-trailing-quotation" }
            self = .value(bytes.dropFirst().dropLast().string)
        } else {
            self = .key(bytes.string)
        }
    }
}

extension Sequence where Iterator.Element == Byte {
    func extractParameters() throws -> [Template.Component.Instruction.Parameter] {
        return try split(separator: .comma)
            .map { $0.array.trimmed(.whitespace) }
            .map { try Template.Component.Instruction.Parameter($0) }
    }
}

extension Sequence where Iterator.Element == Byte {
    static var whitespace: Bytes {
        return [ .space, .newLine, .carriageReturn, .horizontalTab]
    }
}


final class Template {
    // TODO: Bytes?
    // reference only
    let raw: String
    let components: [Component]

    init(raw: String) throws {
        self.raw = raw
        var buffer = Buffer(raw.bytes.trimmed(.whitespace).array)
        self.components = try buffer.components()
    }
}

extension Template {
    enum Component {
        final class Instruction {
            enum Parameter {
                case variable(String)
                case constant(String)
            }

            let name: String
            let parameters: [Parameter]

            let body: Template?

            fileprivate var isChain: Bool

            init(name: String, parameters: [Parameter], body: String?) throws {
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
                self.body = try body.flatMap { try Template(raw: $0) }
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

final class If: CMD {
    let name = "if"
    func process(arguments: [Argument], parent: RenderContext) throws -> RenderContext? {
        guard arguments.count == 1 else { throw "invalid if statement arguments" }
        let argument = arguments[0]
        // TODO: Polymorphic could help here
        switch argument {
        case let .constant(value: value):
            let bool = Bool(value)
            return bool == true ? parent : nil
        case let .variable(key: _, value: value as Bool):
            return value ? parent : nil
        case let .variable(key: _, value: value as String):
            let bool = Bool(value)
            return bool == true ? parent : nil
        case let .variable(key: _, value: value as Int):
            return value == 1 ? parent : nil
        case let .variable(key: _, value: value as Double):
            return value == 1.0 ? parent: nil
        case let .variable(key: _, value: value):
            return value != nil ? parent : nil
        }
    }
}

final class Else: CMD {
    let name = "else"

    func process(arguments: [Argument], parent: RenderContext) throws -> RenderContext? {
        guard arguments.isEmpty else { throw "else expects 0 arguments" }
        // else is a path through to parent context
        return parent
    }
}

final class Loop: CMD {
    let name = "loop"
    func preprocess(instruction: Template.Component.Instruction, with context: RenderContext) -> [Argument] {
        var input = [Argument]()
        instruction.parameters.forEach { arg in
            switch arg {
            case let .variable(key):
                let value = context.get(key)
                input.append(.variable(key: key, value: value))
            case let .constant(c):
                input.append(.constant(value: c))
            }
        }
        return input
    }
    func process(arguments: [Argument], parent: RenderContext) throws -> RenderContext? {
        print("processing loop: \(arguments)")
        guard arguments.count == 1 else { throw "more than one argument not supported in loop" }
        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            return value
        case let .variable(key: _, value: value):
            print("Got variable: \(value)")
            return value as? RenderContext
        }
    }

    func render(context: RenderContext, with template: Template) throws -> Bytes {
        guard let array = context as? [RenderContext] else {
            throw "Not right value for loop, needs: [RenderContext]"
        }

        return try array.map { try template.render(with: $0) } .flatMap { $0 + [.newLine] }
    }
}

final class Variable: CMD {
    let name = "" // empty name, ie: @(variable)
    func process(arguments: [Argument], parent: RenderContext) throws -> RenderContext? {
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
        // if arguments.isEmpty return { "@" } // temporary escaping mechani
        guard arguments.count == 1 else { throw "invalid var argument" }
        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            return value
        case let .variable(key: _, value: value):
            return value as? RenderContext
        }
    }
}

var _commands: [String: CMD] = [
    "": Variable(),
    "loop": Loop(),
    "if": If(),
    "else": Else()
]

protocol CMD {
    var name: String { get }
    func process(arguments: [Argument], parent: RenderContext) throws -> RenderContext?

    // Optional
    func preprocess(instruction: Template.Component.Instruction, with context: RenderContext) throws -> [Argument]

    // Optional Rendering -- MUST RENDER
    func render(context: RenderContext, with template: Template) throws -> Bytes
}

extension CMD {
    func preprocess(instruction: Template.Component.Instruction, with context: RenderContext) -> [Argument] {
        var input = [Argument]()
        instruction.parameters.forEach { arg in
            switch arg {
            case let .variable(key):
                let value = context.get(key)
                print("Got: \(value)")
                input.append(.variable(key: key, value: value))
            case let .constant(c):
                input.append(.constant(value: c))
            }
        }
        return input
    }

    func render(context: RenderContext, with template: Template) throws -> Bytes {
        return try template.render(with: context)
    }
}


extension Template: CustomStringConvertible {
    var description: String {
        let components = self.components.map { $0.description } .joined(separator: ", ")
        return "Template: " + components
    }
}

extension Template.Component: CustomStringConvertible {
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

extension Template.Component.Instruction: CustomStringConvertible {
    var description: String {
        return "(name: \(name), parameters: \(parameters), body: \(body)"
    }
}

extension Template.Component.Instruction.Parameter: CustomStringConvertible {
    var description: String {
        switch self {
        case let .variable(v):
            return ".variable(\(v))"
        case let .constant(c):
            return ".constant(\(c))"
        }
    }
}

extension Template.Component: Equatable {}
func == (lhs: Template.Component, rhs: Template.Component) -> Bool {
    switch (lhs, rhs) {
    case let (.raw(l), .raw(r)):
        return l == r
    case let (.instruction(l), .instruction(r)):
        return l == r
    default:
        return false
    }
}

extension Template: Equatable {}
func == (lhs: Template, rhs: Template) -> Bool {
    return lhs.components == rhs.components
}

extension Template.Component.Instruction: Equatable {}
func == (lhs: Template.Component.Instruction, rhs: Template.Component.Instruction) -> Bool {
    return lhs.name == rhs.name
        && lhs.parameters == rhs.parameters
        && lhs.body == rhs.body
}

extension Template.Component.Instruction.Parameter: Equatable {}
func == (lhs: Template.Component.Instruction.Parameter, rhs: Template.Component.Instruction.Parameter) -> Bool {
    switch (lhs, rhs) {
    case let (.variable(l), .variable(r)):
        return l == r
    case let (.constant(l), .constant(r)):
        return l == r
    default:
        return false
    }
}

extension Template.Component.Instruction.Parameter {
    init(_ bytes: BytesSlice) throws {
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

extension Template {
    func render(with context: RenderContext) throws -> Bytes {
        var buffer = Bytes()
        try components.forEach { component in
            switch component {
            case let .raw(r):
                buffer += r
            case let .instruction(instruction):
                print("Instruction: \(instruction)")
                guard let command = _commands[instruction.name] else { throw "unsupported command" }
                let arguments = try command.preprocess(instruction: instruction, with: context)
                print("Arguments: \(arguments)")
                // empty is ok -- on chains, chain here
                guard let subcontext = try command.process(arguments: arguments, parent: context) else { return }
                let renderedComponent = try instruction.body.flatMap { subtemplate in
                    // command MUST do render here for things like 'loop', consider top-level change as well
                    return try command.render(context: subcontext, with: subtemplate)
                } ?? subcontext.raw

                guard let bytes = renderedComponent else { return }
                buffer += bytes
            case let .chain(chain):
                for instruction in chain {
                    guard let command = _commands[instruction.name] else { throw "unsupported command" }
                    let arguments = try command.preprocess(instruction: instruction, with: context)
                    print("Arguments: \(arguments)")
                    // empty is ok -- on chains, chain here
                    guard let subcontext = try command.process(arguments: arguments, parent: context) else { continue }
                    let renderedComponent = try instruction.body
                        .flatMap { subtemplate in
                            // command MUST do render here for things like 'loop', consider top-level change as well
                            return try command.render(context: subcontext, with: subtemplate)
                        }
                        ?? subcontext.raw

                    guard let bytes = renderedComponent else { continue }
                    buffer += bytes
                    break // break loop if we found a component
                }
            }

        }
        return buffer
    }
}


struct Instruction {
    /**
     
     RETURN
     
     - Context: -- pass context to body
     - String: -- String to use
     - nil: omit usage
    */
    typealias ProcessArguments = (context: RenderContext, arguments: [String]) -> RenderContext?
    typealias EvaluateBody = (context: RenderContext) -> String


    let name: String
    let arguments: [InstructionArgument]

    let body: Template?

    init(name: String, arguments: [InstructionArgument], body: String?) throws {
        self.name = name
        self.arguments = arguments
        self.body = try body.flatMap { try Template(raw: $0) }
    }

    func makeCommandInput(from context: RenderContext) throws -> [Any?] {
        var input = [Optional<Any>]()
        arguments.forEach { arg in
            switch arg {
            case let .key(k):
                if let exists = context.get(k) { input.append(exists) }
                    // TODO: Should this just be the key instead of append nil.
                else { input.append(nil) }
            case let .value(v):
                input.append(v)
            }
        }
        return input
    }
}

extension Template.Component {
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
