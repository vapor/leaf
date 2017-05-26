extension Stem {
    /*
        Renders a given leaf with the given context
    */
    public func render(_ leaf: Leaf, with context: Context) throws -> Bytes {
        let initialQueue = context.queue
        defer { context.queue = initialQueue }
        var buffer = Bytes()
        for component in leaf.components {
            switch component {
            case let .raw(bytes):
                buffer += bytes
            case let .tagTemplate(tagTemplate):
                let (tag, value, shouldRender) = try process(tagTemplate, leaf: leaf, context: context)
                guard shouldRender else { continue }
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
                    guard shouldRender else { continue } // inner loop
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
        context: Context
        ) throws -> (tag: Tag, value: Node?, shouldRender: Bool) {
        guard let tag = tags[tagTemplate.name] else { throw ParseError.tagTemplateNotFound(name: tagTemplate.name) }
        
        let arguments = try tag.makeArguments(
            stem: self,
            context: context,
            tagTemplate: tagTemplate
        )

        let value = try tag.run(
            tagTemplate: tagTemplate,
            arguments: arguments
        )

        let shouldRender = tag.shouldRender(
            tagTemplate: tagTemplate,
            arguments: arguments,
            value: value
        )
        return (tag, value, shouldRender)
    }

    private func render(
        tag: Tag,
        context: Context,
        value: Node?,
        tagTemplate: TagTemplate) throws -> Bytes {
        // return "World".makeBytes()
        if let subLeaf = tagTemplate.body {
            if let val = value {
                context.push(["self": val])
                defer { context.pop() }
            }
            return try tag.render(stem: self, context: context, value: value, leaf: subLeaf)
        } else if let rendered = try value?.rendered() {
            return rendered
        }
        return []
    }

}
