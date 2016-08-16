import Core
import Foundation

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

protocol Context {
    var raw: Bytes? { get }
    func get(_ key: String) -> Context?
}

extension Context {
    var raw: Bytes? {
        guard let cs = self as? CustomStringConvertible else { return nil }
        return cs.description.bytes
    }

    func get(_ key: String) -> Context? {
        guard key == "self" else { return nil }
        return self
    }
}

extension Dictionary: Context {
    func get(_ key: String) -> Context? {
        if key == "self" { return self }
        guard let k = key as? Key else { return nil }
        return self[k] as? Context
    }
}

extension Context {
    var functions: [String: (Context) -> Context] { return [:] }
}
// typealias Loader = (arguments: [Context]) -> String


enum Token {
    case variable(contents: String)
    case function(name: String, arguments: [Context], contents: String)
}

enum Either<A,B> {
    case a(A)
    case b(B)
}

extension Byte {
    var isTemplateToken: Bool {
        return self == .at
            || self == .forwardSlash
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

extension String: Context {}
extension String: CustomStringConvertible {
    public var description: String { return self }
}

protocol Command {
    var name: String { get }
    func process(arguments: [Any?]) throws -> Context?
}

let varCommand = Var()
let COMMANDS: [String: Command] = [ varCommand.name: varCommand ]

struct Var: Command {
    let name = ""
    func process(arguments: [Any?]) throws -> Context? {
        guard arguments.count == 1 else { throw "invalid var argument" }
        guard let stringable = arguments.first as? CustomStringConvertible else { throw "variable command requires CustomStringConvertible" }
        return stringable.description
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
        if token == .at {
            let instruction = try extractInstruction()
            return .instruction(instruction)
        } else {
            let raw = extractUntil { (byte) -> Bool in
                return byte == .at && previous != .backSlash
            }
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
        guard current == .space, next == .openCurly else { return try Instruction(name: name, arguments: arguments, body: nil) }
        moveForward() // queue up `{`

        // TODO: Body should be template components
        let body = try extractBody()
        return try Instruction(name: name, arguments: arguments, body: body)
    }

    mutating func extractInstructionName() throws -> String {
        // TODO: Validate alphanumeric
        return try extractSection(opensWith: .at, closesWith: .openParenthesis)
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
        var buffer = Buffer(raw.bytes)
        self.components = try buffer.components()
    }

    func render(with context: Context) throws -> Bytes {
        var buffer = Bytes()

        try components.forEach { component in
            switch component {
            case let .raw(r):
                buffer += r.bytes
            case let .instruction(i):
                guard let command = COMMANDS[i.name] else { fatalError("unsupported command") }
                let input = try i.makeCommandInput(from: context)
                buffer += try command.process(arguments: input)
                    .flatMap { try i.body?.render(with: $0) ?? $0.raw }
                    ?? []
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
    typealias ProcessArguments = (context: Context, arguments: [String]) -> Context?
    typealias EvaluateBody = (context: Context) -> String


    let name: String
    let arguments: [InstructionArgument]

    let body: Template?

    init(name: String, arguments: [InstructionArgument], body: String?) throws {
        self.name = name
        self.arguments = arguments
        self.body = try body.flatMap { try Template(raw: $0) }
    }

    func makeCommandInput(from context: Context) throws -> [Any?] {
        var input = [Optional<Any>]()
        arguments.forEach { arg in
            switch arg {
            case let .key(k):
                if let exists = context.get(k) { input.append(exists) }
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
    let handler: ([InstructionArgument]) throws -> Context?
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
    case command(Context)
}


func doStuff(input: String) {
    //    let buffer = StaticDataBuffer(bytes: input.bytes)

    //var iterator = input.bytes.makeIterator()
    //while let n = iterator.next() {
    //}
}
