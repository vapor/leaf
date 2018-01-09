/// An expression, like `1 + 2`, `!1`, and `a || b`
public enum TemplateExpression {
    case infix(operator: ExpressionInfixOperator, left: TemplateSyntax, right: TemplateSyntax)
    case prefix(operator: ExpressionPrefixOperator, right: TemplateSyntax)
    case postfix(operator: ExpressionPostfixOperator, left: TemplateSyntax)
}

/// a <op> a
public enum ExpressionInfixOperator {
    case add
    case subtract
    case lessThan
    case greaterThan
    case multiply
    case divide
    case equal
    case notEqual
    case and
    case or
}

/// <op>a
public enum ExpressionPrefixOperator {
    case not
}

/// a<op>
public enum ExpressionPostfixOperator {}

extension TemplateExpression: CustomStringConvertible {
    public var description: String {
        switch self {
        case .infix(let op, let left, let right): return "\(left) \(op) \(right)"
        case .prefix(let op, let right): return "\(op)\(right)"
        case .postfix(let op, let left): return "\(left)\(op)"
        }
    }
}

