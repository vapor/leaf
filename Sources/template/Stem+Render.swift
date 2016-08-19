extension Stem {
    public func render(_ leaf: Leaf, with filler: Scope) throws -> Bytes {
        let initialQueue = filler.queue
        defer { filler.queue = initialQueue }

        var buffer = Bytes()
        try leaf.components.forEach { component in
            switch component {
            case let .raw(bytes):
                buffer += bytes
            case let .tagTemplate(tagTemplate):
                let (tag, value, shouldRender) = try process(tagTemplate, leaf: leaf, scope: filler)
                guard shouldRender else { return }
                buffer += try render(tag: tag, scope: filler, value: value, tagTemplate: tagTemplate)
            case let .chain(chain):
                for tagTemplate in chain {
                    /**
                     *********************
                     ****** WARNING ******
                     *********************

                     Deceptively similar to above, nuance will break e'rything!
                     **/
                    let (tag, value, shouldRender) = try process(tagTemplate, leaf: leaf, scope: filler)
                    guard shouldRender else { continue }
                    buffer += try render(tag: tag, scope: filler, value: value, tagTemplate: tagTemplate)
                    // Once a link in the chain is marked as pass (shouldRender),
                    // MUST break forEach scope
                    break
                }
            }
        }
        return buffer
    }

    private func process(
        _ tagTemplate: TagTemplate,
        leaf: Leaf,
        scope: Scope) throws -> (tag: Tag, value: Any?, shouldRender: Bool) {

        guard let tag = tags[tagTemplate.name] else { throw "unsupported tagTemplate" }

        let arguments = try tag.makeArguments(
            stem: self,
            filler: scope,
            tagTemplate: tagTemplate
        )

        let value = try tag.run(
            stem: self,
            filler: scope,
            tagTemplate: tagTemplate,
            arguments: arguments
        )

        let shouldRender = tag.shouldRender(
            stem: self,
            filler: scope,
            tagTemplate: tagTemplate,
            arguments: arguments,
            value: value
        )

        return (tag, value, shouldRender)
    }

    private func render(tag: Tag, scope: Scope, value: Any?, tagTemplate: TagTemplate) throws -> Bytes {
        switch value {
            /**
             ** Warning **
             MUST parse out non-optional explicitly to
             avoid printing strings as `Optional(string)`
             */
        case let val?:
            scope.push(["self": val])
        default:
            scope.push(["self": value])
        }
        defer { scope.pop() }

        if let subLeaf = tagTemplate.body {
            return try tag.render(stem: self, filler: scope, value: value, template: subLeaf)
        } else if let rendered = try scope.renderedSelf() {
            return rendered
        }
        
        
        return []
    }

}
