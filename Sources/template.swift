import Core
import Foundation

let TOKEN: Byte = .at

extension String: Swift.Error {}
//let _ = "Hello, \\(variable)!"


// "blah blah @forEach friends { Hello, \(name)! }"
// =>
// Hello, Joe! Hello, Jen!
let forLoop = "blah blah @forEach friends { Hello, \\(name)! }"

let context: [String: Any] = [
    "name": "Logan",
    "friends": [
        [
            "name": "Joe"
        ],
        [
            "name": "Jen"
        ]
    ]
]

// temporary global

import Foundation

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
        if key == "self" { return self }
        guard let k = key as? Key else { return nil }
        return self[k] as? RenderContext
    }
}

extension RenderContext {
    // var functions: [String: (RenderContext) -> RenderContext] { return [:] }
}
// typealias Loader = (arguments: [Context]) -> String


enum Token {
    case variable(contents: String)
    case function(name: String, arguments: [RenderContext], contents: String)
}

enum Either<A,B> {
    case a(A)
    case b(B)
}

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

protocol Command {
    var name: String { get }
    func process(arguments: [Any?]) throws -> RenderContext?
}

enum CommandInput {
    case variable(name: String)
    case value(String)
}

protocol AltCommand {
    var name: String { get }

    func process(input: [CommandInput], in context: RenderContext) throws -> RenderContext?
    func render(template: Template, in context: RenderContext) throws -> Bytes
}

extension AltCommand {
    func process(input: [CommandInput], in context: RenderContext) throws -> RenderContext? {
        
        return nil
    }

    func render(template: Template, in context: RenderContext) throws -> Bytes {
        return try template.render(with: context)
    }
}

struct LoopCommand: AltCommand {
    let name = "loop"
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
            comps.append(next)
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
        if let current = current { collection.append(current) }
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
        let parameters = try extractInstructionParameters()

        // check if body
        moveForward()
        guard current == .space, next == .openCurly else {
            return try Template.Component.Instruction(name: name, parameters: parameters, body: nil)
        }
        moveForward() // queue up `{`

        // TODO: Body should be template components
        let body = try extractBody()
        moveForward()
        return try Template.Component.Instruction(name: name, parameters: parameters, body: body)
    }

    mutating func extractInstructionName() throws -> String {
        // TODO: Validate alphanumeric
        return try extractSection(opensWith: TOKEN, closesWith: .openParenthesis)
            .string
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
            throw "invalid body, missing closer: \([closer].string)"
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

            init(name: String, parameters: [Parameter], body: String?) throws {
                self.name = name
                self.parameters = parameters
                self.body = try body.flatMap { try Template(raw: $0) }
            }
        }

        case raw(Bytes)
        case instruction(Instruction)
    }
}

enum Argument {
    case variable(key: String, value: Any?)
    case constant(value: String)
}


final class Variable: CMD {
    let name = "" // empty name, ie: @(variable)
    func process(arguments: [Argument]) throws -> RenderContext? {
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
    "": Variable()
]

protocol CMD {
    var name: String { get }
    func process(arguments: [Argument]) throws -> RenderContext?

    // Optional
    func preprocess(instruction: Template.Component.Instruction, with context: RenderContext) -> [Argument]
}

extension CMD {
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
        print("Rendering with: \(context)")
        var buffer = Bytes()

        print("Components: \(components)")
        print("")
        try components.forEach { component in
            switch component {
            case let .raw(r):
                buffer += r
            case let .instruction(instruction):
                print("Instruction: \(instruction)")
                guard let command = _commands[instruction.name] else { throw "unsupported command" }
                let arguments = command.preprocess(instruction: instruction, with: context)
                print("Arguments: \(arguments)")
                // empty is ok -- on chains, chain here
                let subcontext = try command.process(arguments: arguments)
                print("Subcontext: \(subcontext)")
                print("Instruction body: \(instruction.body)")

                guard
                    let bytes = try instruction.body?.render(with: subcontext!) ?? subcontext!.raw
                    else { return }

                print("Appending: \(bytes.string)")
                buffer += bytes
                print("Appended : \(buffer.string)")
                print("")
                // guard let subcontext = try command.process(arguments: arguments) else {
                // buffer +=  try subcontext.flatMap { ctxt in
                //  return instruction.body?.render(with: ctxt) ?? ctxt.raw
                // }

                /*
                guard let command = COMMANDS[i.name] else { fatalError("unsupported command") }
                let input = try i.makeCommandInput(from: context)
                let rendered: Bytes = try command.process(arguments: input)
                    .flatMap {
                        print("Sub render: \(i.body?.raw) with: \($0)")
                        let r =  try i.body?.render(with: $0) ?? $0.raw
                        print("R: \(r?.string)")
                        print("")
                        return r
                    }
                    ?? []

                print("RENDERED: \(rendered.string)")
                print("")
                buffer += rendered
                 */
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

struct ___Instruction {
    let name: String
    let handler: ([InstructionArgument]) throws -> RenderContext?
}

let ifInstruction = ___Instruction(name: "if") { args in
    // guard args.count == 1, let statement =
    return nil
}

// class TemplateRenderer {
//
// }



enum Section {
    case raw(String)
    case command(RenderContext)
}


func doStuff(input: String) {
    //    let buffer = StaticDataBuffer(bytes: input.bytes)

    //var iterator = input.bytes.makeIterator()
    //while let n = iterator.next() {
    //}
}
