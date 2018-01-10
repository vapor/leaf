public struct TemplateTag {
    public var name: String
    public var parameters: [TemplateSyntax]
    public var body: [TemplateSyntax]?

    public init(name: String, parameters: [TemplateSyntax], body: [TemplateSyntax]?) {
        self.name = name
        self.parameters = parameters
        self.body = body
    }
}

extension TemplateTag: CustomStringConvertible {
    public var description: String {
        let params = parameters.map { $0.description }
        let hasBody = body != nil ? true : false
        return "\(name)(\(params.joined(separator: ", "))) \(hasBody)"
    }
}
