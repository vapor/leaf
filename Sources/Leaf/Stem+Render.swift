    let val = [String](repeating: "Hello, World!", count: 1000).joined(separator: ", ").bytes
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
                // buffer += "World".bytes
                // let value = Optional(Node("World"))
                // let tag = tags[tagTemplate.name]!
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

        /*
        return (Variable(), Optional(Node("World")), true)
         */

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

    private func render(
        tag: Tag,
        context: Context,
        value: Node?,
        tagTemplate: TagTemplate) throws -> Bytes {
        // return "World".bytes
        if let subLeaf = tagTemplate.body {
            if let val = value { context.push(["self": val]) }
            return try tag.render(stem: self, context: context, value: value, leaf: subLeaf)
        } else if let rendered = try value?.rendered() {
            return rendered
        }
        return []

        
        /*
        switch value {
            /**
             ** Warning **
             MUST parse out non-optional explicitly to
             avoid printing strings as `Optional(string)`
             */
        case let val?:
            context.push(["self": val])
        default:
            context.push(["self": nil])
        }
        defer { context.pop() }

        if let subLeaf = tagTemplate.body {
            return try tag.render(stem: self, context: context, value: value, leaf: subLeaf)
        } else if let rendered = try context.renderedSelf() {
            return rendered
        }
        
        
        return []
 
 */
    }

}
/*
extension Leaf.Component {
    public func render(stem: Stem, leaf: Leaf, with context: Context) throws -> Bytes {
        let initialQueue = context.queue
        defer { context.queue = initialQueue }

        var buffer = Bytes()
        try leaf.components.forEach { component in
            switch component {
            case let .raw(bytes):
                buffer += bytes
            case let .tagTemplate(tagTemplate):
                let (tag, value, shouldRender) = try process(tagTemplate: tagTemplate, stem: stem, leaf: leaf, context: context)
                guard shouldRender else { return }
                buffer += try render(stem: stem, tag: tag, context: context, value: value, tagTemplate: tagTemplate)
            case let .chain(chain):
                for tagTemplate in chain {
                    /**
                     *********************
                     ****** WARNING ******
                     *********************

                     Deceptively similar to above, nuance will break e'rything!
                     **/
                    let (tag, value, shouldRender) = try process(tagTemplate: tagTemplate, stem: stem, leaf: leaf, context: context)
                    guard shouldRender else { continue }
                    buffer += try render(stem: stem, tag: tag, context: context, value: value, tagTemplate: tagTemplate)
                    // Once a link in the chain is marked as pass (shouldRender),
                    // MUST break forEach context
                    break
                }
            }
        }
        return buffer
    }

    private func process(
        tagTemplate: TagTemplate,
        stem: Stem,
        leaf: Leaf,
        context: Context) throws -> (tag: Tag, value: Node?, shouldRender: Bool) {

        guard let tag = stem.tags[tagTemplate.name] else { throw "unsupported tagTemplate" }

        let arguments = try tag.makeArguments(
            stem: stem,
            context: context,
            tagTemplate: tagTemplate
        )

        let value = try tag.run(
            stem: stem,
            context: context,
            tagTemplate: tagTemplate,
            arguments: arguments
        )

        let shouldRender = tag.shouldRender(
            stem: stem,
            context: context,
            tagTemplate: tagTemplate,
            arguments: arguments,
            value: value
        )

        return (tag, value, shouldRender)
    }

    private func render(
        stem: Stem,
        tag: Tag,
        context: Context,
        value: Node?,
        tagTemplate: TagTemplate) throws -> Bytes {
        switch value {
            /**
             ** Warning **
             MUST parse out non-optional explicitly to
             avoid printing strings as `Optional(string)`
             */
        case let val?:
            context.push(["self": val])
        default:
            context.push(["self": nil])
        }
        defer { context.pop() }

        if let subLeaf = tagTemplate.body {
            return try tag.render(stem: stem, context: context, value: value, leaf: subLeaf)
        } else if let rendered = try context.renderedSelf() {
            return rendered
        }
        
        
        return []
    }
}
*/
