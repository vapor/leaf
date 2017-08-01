import Bits

indirect enum SyntaxKind {
    case raw(data: Bytes)
    case tag(name: String, parameters: [Syntax], indent: Int, body: [Syntax]?, chained: Syntax?)
    case identifier(name: String)
    case constant(Constant)
    case expression(type: Operator, left: Syntax, right: Syntax)
    case not(Syntax)
}

enum Operator {
    case add
    case subtract
    case lessThan
    case greaterThan
    case multiply
    case divide
}

enum Constant {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string([Syntax])
}


public struct Syntax {
    let kind: SyntaxKind
    let source: Source
}

public struct Source {
    let line: Int
    let column: Int
    let range: Range<Int>
}

internal struct SourceStart {
    let line: Int
    let column: Int
    let rangeStart: Int
}

extension ByteScanner {
    func makeSourceStart() -> SourceStart {
        return SourceStart(line: line, column: column, rangeStart: offset)
    }

    func makeSource(using sourceStart: SourceStart) -> Source {
        return Source(
            line: sourceStart.line,
            column: sourceStart.column,
            range: sourceStart.rangeStart..<offset
        )
    }
}

extension Syntax: CustomStringConvertible {
    public var description: String {
        switch kind {
        case .raw(let source):
            return "Raw: `\(source.makeString())`"
        case .tag(let name, let params, _, let body, _):
            let params = params.map { $0.description }
            let hasBody = body != nil ? true : false
            return "Tag: \(name)(\(params.joined(separator: ", "))) Body: \(hasBody)"
        case .identifier(let name):
            return "`\(name)`"
        case .expression(let type, let left, let right):
            return "Expr: (\(left) \(type) \(right))"
        case .constant(let const):
            return "c:\(const)"
        case .not(let syntax):
            return "!:\(syntax)"
        }
    }
}

extension Constant: CustomStringConvertible {
    var description: String {
        switch self {
        case .bool(let bool):
            return bool.description
        case .double(let double):
            return double.description
        case .int(let int):
            return int.description
        case .string(let ast):
            return "(" + ast.map { $0 .description }.joined(separator: ", ") + ")"
        }
    }
}
