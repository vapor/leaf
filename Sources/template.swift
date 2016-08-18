import Core
import Foundation

/*
 // TODO: GLOBAL

 - Context tree, so if variable isn't in lowest scope, we can search higher context
 - Filler passed into Driver should have same amount in queue as it does AFTER. Warn or Assert
 - Filters/Modifiers are supported longform, consider implementing short form.
 */

let TOKEN: Byte = .at

final class Filler {
    // FILO
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
        moveForward()
        return try Template.Component.Instruction(name: name, parameters: parameters, body: body)
    }

    mutating func extractInstructionName() throws -> String {
        // can't extract section because of @@
        guard current == TOKEN else { throw "instruction name must lead with token" }
        moveForward() // drop initial token from name. a secondary token implies chain
        let name = extractUntil { $0 == .openParenthesis }
        guard current == .openParenthesis else { throw "instruction names must be alphanumeric and terminated with '('" }
        return name.string
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

extension Sequence where Iterator.Element == Byte {
    func extractParameters() throws -> [Template.Component.Instruction.Parameter] {
        return try split(separator: .comma)
            .map { try Template.Component.Instruction.Parameter.init($0) }
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
            enum Param {
                enum PathComponent {
                    case key(String)
                    case filter(String)
                }

                case variable(path: [PathComponent])
                case constant(value: String)
            }

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

protocol _Renderable {
    func rendered() throws -> Bytes
}

protocol _InstructionDriver {
    var name: String { get }

    // Optional -- takes template instruction and populates it from fillter
    func preprocess(instruction: Template.Component.Instruction, with filler: Filler) throws -> [Argument]
    // The processing of arguments within the filler, and returning a new context
    func process(arguments: [Argument], with filler: Filler) throws -> Bool

    func render(template: Template, with filler: Filler) throws -> Bytes

    func postrender(filler: Filler) throws
}


extension _InstructionDriver {
    func preprocess(instruction: Template.Component.Instruction, with filler: Filler) -> [Argument] {
        var input = [Argument]()
        instruction.parameters.forEach { arg in
            switch arg {
            case let .variable(key):
                if key == "self" {
                    input.append(.variable(key: key, value: filler.get(path: "self")))
                } else {
                    let value = filler.get(path: key)
                    input.append(.variable(key: key, value: value))
                }
            case let .constant(c):
                input.append(.constant(value: c))
            }
        }
        return input
    }

    func process(arguments: [Argument], with filler: Filler) throws -> Bool {
        guard arguments.count == 1 else {
            throw "more than one argument not supported, override \(#function) for custom behavior"
        }

        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            filler.push(["self": value])
        case let .variable(key: _, value: value as FuzzyAccessible):
            filler.push(value)
        case let .variable(key: _, value: value):
            filler.push(["self": value])
        }

        return true // should continue
    }

    func render(template: Template, with filler: Filler) throws -> Bytes {
        return try template.render(with: filler)
    }

    func postrender(filler: Filler) throws {}
}

final class _Loop: _InstructionDriver {
    let name = "loop"

    func process(arguments: [Argument], with filler: Filler) throws -> Bool {
        guard arguments.count == 2 else {
            throw "loop requires two arguments, var w/ array, and constant w/ sub name"
        }

        switch (arguments[0], arguments[1]) {
        case let (.variable(key: _, value: value?), .constant(value: innername)):
            let array = value as? [Any] ?? [value]
            filler.push(array.map { [innername: $0] })
            return true
        default:
            return false
        }
    }

    func render(template: Template, with filler: Filler) throws -> Bytes {
        guard let array = filler.queue.last as? [Any] else { fatalError() }

        // return try array.map { try template.render(with: $0) } .flatMap { $0 + [.newLine] }
        return try array
            .map { item -> Bytes in
                if let i = item as? FuzzyAccessible {
                    filler.push(i)
                } else {
                    filler.push(["self": item])
                }

                let rendered = try template.render(with: filler)
                filler.pop()
                return rendered
            }
            .flatMap { $0 + [.newLine] }

        //return []
    }

    func postrender(filler: Filler) throws {
        filler.pop()
    }
}

final class _Uppercased: _InstructionDriver {
    let name = "uppercased"

    func process(arguments: [Argument], with filler: Filler) throws -> Bool {
        guard arguments.count == 1 else { throw "uppercase only accepts single arguments" }
        switch arguments[0] {
        case let .constant(value: value):
            filler.push(["self": value.uppercased()])
        case let .variable(key: _, value: value as String):
            filler.push(["self": value.uppercased()])
        case let .variable(key: _, value: value as _Renderable):
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

final class _Else: _InstructionDriver {
    let name = "else"

    func process(arguments: [Argument], with filler: Filler) throws -> Bool {
        guard arguments.isEmpty else { throw "else expects 0 arguments" }
        return true
    }
}

final class _If: _InstructionDriver {
    let name = "if"
    func process(arguments: [Argument], with filler: Filler) throws -> Bool {
        guard arguments.count == 1 else { throw "invalid if statement arguments" }
        let argument = arguments[0]
        // TODO: Polymorphic could help here
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

final class _Variable: _InstructionDriver {
    let name = "" // empty name, ie: @(variable)
    func process(arguments: [Argument], with filler: Filler) throws -> Bool {
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
            filler.push(["self": value])
            return true
        case let .variable(key: _, value: value?):
            filler.push(["self": value])
            return true
        default:
            return false
        }
    }

    func postrender(filler: Filler) throws {
        filler.pop()
    }
}

let drivers: [String: _InstructionDriver] = [
    "": _Variable(),
    "if": _If(),
    "else": _Else(),
    "loop": _Loop(),
    "uppercased": _Uppercased()
]

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

extension Template.Component.Instruction.Param.PathComponent {
    init(_ slice: BytesSlice) {
        if slice.suffix(2) == [.openParenthesis, .closedParenthesis] {
            self = .filter(slice.dropLast(2).string)
        } else {
            self = .key(slice.string)
        }
    }
}

extension Template.Component.Instruction.Param {
    init(alt bytes: BytesSlice) throws {
        let bytes = bytes.array.trimmed(.whitespace)
        guard !bytes.isEmpty else { throw "invalid argument: empty" }
        if bytes.first == .quotationMark {
            guard bytes.count > 1 && bytes.last == .quotationMark else { throw "invalid argument: missing-trailing-quotation" }
            self = .constant(value: bytes.dropFirst().dropLast().string)
        } else {
            let params = bytes.split(separator: .period, omittingEmptySubsequences: true)
                .map { PathComponent($0) }
            self = .variable(path: params)
        }
    }
}

extension Template.Component.Instruction.Parameter {
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
        guard let renderable = value as? _Renderable else { return "\(value)".bytes }
        return try renderable.rendered()
    }
}

extension Template {
    func render(with filler: Filler) throws -> Bytes {
        var buffer = Bytes()
        try components.forEach { component in
            switch component {
            case let .raw(bytes):
                buffer += bytes
            case let .instruction(instruction):
                guard let command = drivers[instruction.name] else { throw "unsupported instruction" }

                let arguments = try command.preprocess(instruction: instruction, with: filler)
                print(arguments)
                let shouldRender = try command.process(arguments: arguments, with: filler)
                print(shouldRender)
                guard shouldRender else { return }
                if let template = instruction.body {
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
