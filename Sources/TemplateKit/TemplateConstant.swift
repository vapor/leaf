/// Supported template constants.
public enum TemplateConstant {
    case bool(Bool)
    case int(Int)
    case double(Double)
    /// Strings support nested stynax.
    case string([TemplateSyntax])
}

extension TemplateConstant: CustomStringConvertible {
    public var description: String {
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
