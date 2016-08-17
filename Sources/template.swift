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
    mutating func components() throws -> [TemplateComponent] {
        var comps = [TemplateComponent]()
        while let next = try nextComponent() {
            comps.append(next)
        }
        return comps
    }

    mutating func nextComponent() throws -> TemplateComponent? {
        guard let token = current else { return nil }
        if token == TOKEN {
            let instruction = try extractInstruction()
            return .instruction(instruction)
        } else {
            let raw = extractUntil { $0.isTemplateToken }
            return .raw(raw.string)
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
    mutating func extractInstruction() throws -> Instruction {
        let name = try extractInstructionName()
        let arguments = try extractArguments()

        // check if body
        moveForward()
        guard current == .space, next == .openCurly else {
            return try Instruction(name: name, arguments: arguments, body: nil)
        }
        moveForward() // queue up `{`

        // TODO: Body should be template components
        let body = try extractBody()
        moveForward()
        return try Instruction(name: name, arguments: arguments, body: body)
    }

    mutating func extractInstructionName() throws -> String {
        // TODO: Validate alphanumeric
        return try extractSection(opensWith: TOKEN, closesWith: .openParenthesis)
            .string
    }

    mutating func extractArguments() throws -> [InstructionArgument] {
        return try extractSection(opensWith: .openParenthesis, closesWith: .closedParenthesis)
            .extractArguments()
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
    func extractArguments() throws -> [InstructionArgument] {
        return try split(separator: .comma)
            .map { $0.array.trimmed(.whitespace) }
            .map { try InstructionArgument($0) }
    }
}

extension Sequence where Iterator.Element == Byte {
    static var whitespace: Bytes {
        return [ .space, .newLine, .carriageReturn, .horizontalTab]
    }
}


class Template {
    let raw: String
    let components: [TemplateComponent]

    init(raw: String) throws {
        self.raw = raw
        var buffer = Buffer(raw.bytes.trimmed(.whitespace).array)
        self.components = try buffer.components()
    }

    func render(with context: RenderContext) throws -> Bytes {
        print("Rendering with: \(context)")
        var buffer = Bytes()

        try components.forEach { component in
            switch component {
            case let .raw(r):
                print("Appending: \(r)")
                buffer += r.bytes
            case let .instruction(i):
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
            }
        }

        print("Collected buffer: \(buffer.string)")
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
        self.body = try body.flatMap { print("RAW: \($0)"); return try Template(raw: $0) }
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
