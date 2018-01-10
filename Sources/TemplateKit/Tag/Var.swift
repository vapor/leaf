import Async

/// Sets data to the tag context.
public final class Var: TagRenderer {
    public init() {}

    /// See TagRenderer.render
    public func render(tag: TagContext) throws -> Future<TemplateData> {
        var dict = tag.context.data.dictionary ?? [:]
        switch tag.parameters.count {
        case 1:
            let body = try tag.requireBody()
            guard let key = tag.parameters[0].string else {
                throw tag.error(reason: "Unsupported key type")
            }

            return tag.serializer.serialize(ast: body).map(to: TemplateData.self) { view in
                dict[key] = .data(view.data)
                tag.context.data = .dictionary(dict)
                return .null
            }
        case 2:
            guard let key = tag.parameters[0].string else {
                throw tag.error(reason: "Unsupported key type")
            }
            dict[key] = tag.parameters[1]
            tag.context.data = .dictionary(dict)
            return Future(.null)
        default:
            try tag.requireParameterCount(2)
            return Future(.null)
        }
    }
}
