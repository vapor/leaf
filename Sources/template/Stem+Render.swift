extension Stem {
    public func render(_ leaf: Leaf, with context: Context) throws -> Bytes {
        let initialQueue = context.queue
        defer { context.queue = initialQueue }

        var buffer = Bytes()
        try leaf.components.forEach { component in
            switch component {
            case let .raw(bytes):
                buffer += bytes
            case let .tagTemplate(tagTemplate):
                let (tag, value, shouldRender) = try process(tagTemplate, leaf: leaf, context: context)
                guard shouldRender else { return }
                buffer += try render(tag: tag, context: context, value: value, tagTemplate: tagTemplate)
            case let .chain(chain):
                for tagTemplate in chain {
                    /**
                     *********************
                     ****** WARNING ******
                     *********************

                     Deceptively similar to above, nuance will break e'rything!
                     **/
                    let (tag, value, shouldRender) = try process(tagTemplate, leaf: leaf, context: context)
                    guard shouldRender else { continue }
                    buffer += try render(tag: tag, context: context, value: value, tagTemplate: tagTemplate)
                    // Once a link in the chain is marked as pass (shouldRender),
                    // MUST break forEach context
                    break
                }
            }
        }
        return buffer
    }

    private func process(
        _ tagTemplate: TagTemplate,
        leaf: Leaf,
        context: Context) throws -> (tag: Tag, value: Any?, shouldRender: Bool) {

        guard let tag = tags[tagTemplate.name] else { throw "unsupported tagTemplate" }

        let arguments = try tag.makeArguments(
            stem: self,
            context: context,
            tagTemplate: tagTemplate
        )

        let value = try tag.run(
            stem: self,
            context: context,
            tagTemplate: tagTemplate,
            arguments: arguments
        )

        let shouldRender = tag.shouldRender(
            stem: self,
            context: context,
            tagTemplate: tagTemplate,
            arguments: arguments,
            value: value
        )

        return (tag, value, shouldRender)
    }

    private func render(tag: Tag, context: Context, value: Any?, tagTemplate: TagTemplate) throws -> Bytes {
        switch value {
            /**
             ** Warning **
             MUST parse out non-optional explicitly to
             avoid printing strings as `Optional(string)`
             */
        case let val?:
            context.push(["self": val])
        default:
            context.push(["self": value])
        }
        defer { context.pop() }

        if let subLeaf = tagTemplate.body {
            return try tag.render(stem: self, context: context, value: value, leaf: subLeaf)
        } else if let rendered = try context.renderedSelf() {
            return rendered
        }
        
        
        return []
    }

}
