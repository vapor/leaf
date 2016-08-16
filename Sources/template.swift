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

}

extension Context {
    var functions: [String: (Context) -> Context] { return [:] }
}
typealias Loader = (arguments: [Context]) -> String


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

class TemplateRenderer {
    let rawTemplate: String
    var instructions: [(Context) throws -> Either<String, Context>] = []

    init(rawTemplate: String) {
        self.rawTemplate = rawTemplate
    }

    private func loadTemplate() {
        let buffer = StaticDataBuffer(bytes: rawTemplate.bytes)
        
        var iterator = rawTemplate.bytes.makeIterator()

        var currentBuffer = [Character]()
        while let next = iterator.next() {
            // Assert wasn't lead by `\` escaped

        }
    }
}

protocol BufferProtocol {
    associatedtype Element
    var previous: Element? { get }
    var current: Element? { get }
    var next: Element? { get }

    @discardableResult
    func moveForward() -> Element?
}

class Buffer<T>: BufferProtocol {
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
    func moveForward() -> T? {
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

/*
 Syntax
 
 @ + '<bodyName>` + `(` + `<[argument]>` + `)` + ` { ` + <body> + ` }`
 */
extension BufferProtocol where Element == Byte {
    func extractInstruction() throws -> (name: String, arguments: String, body: String?) {
        let name = try extractInstructionName()
        let arguments = try extractArguments()
        // check if body
        guard current == .space, next == .openCurly else { return (name.string, arguments.string, nil) }
        moveForward() // queue up `{`
        let body = try extractBody()
        return (name.string, arguments.string, body.string)
    }

    func extractInstructionName() throws -> Bytes {
        // TODO: Validate alphanumeric
        return try extractSection(opensWith: .at, closesWith: .openParenthesis)
    }

    func extractArguments() throws -> Bytes {
        return try extractSection(opensWith: .openParenthesis, closesWith: .closedParenthesis)
    }

    func extractBody() throws -> Bytes {
        return try extractSection(opensWith: .openCurly, closesWith: .closedCurly)
            .trimmed(.whitespace)
            .array
    }

    func extractSection(opensWith opener: Byte, closesWith closer: Byte) throws -> Bytes {
        guard current ==  opener else {
            throw "invalid body, missing opener: \([opener].string)"
        }

        var subBodies = 0
        var body = Bytes()
        while let value = moveForward() {
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

extension Sequence where Iterator.Element == Byte {
    static var whitespace: Bytes {
        return [ .space, .newLine, .carriageReturn, .horizontalTab]
    }
}


class Template {
    let raw: String
    var instructions: [Any] = []

    init(raw: String) {
        self.raw = raw
    }

    private func loadInstructions() {
        let characters = Buffer(raw.characters)

        var currentBuffer = [Character]()
        while let value = characters.moveForward() {
            if value == "@" {
                if characters.previous == "/" {
                    currentBuffer.removeLast()
                    currentBuffer.append("@")
                } else if characters.next == "@" {
                    // chain command
                    fatalError("Chain command not implemented")
                } else {

                }

            } else {
                currentBuffer.append(value)
            }
        }

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
    let processArguments: ProcessArguments
    let evaluateBody: EvaluateBody
}
// class TemplateRenderer {
//
// }



enum Section {
    case raw(String)
    case command(Context)
}
extension IteratorProtocol where Element == Character {

}

func doStuff(input: String) {
    //    let buffer = StaticDataBuffer(bytes: input.bytes)

    //var iterator = input.bytes.makeIterator()
    //while let n = iterator.next() {
    //}
}
