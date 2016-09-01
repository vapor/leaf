extension Stem {
    public func spawnLeaf(raw: String) throws -> Leaf {
        return try spawnLeaf(raw: raw.bytes)
    }

    public func spawnLeaf(raw: Bytes) throws -> Leaf {
        let raw = raw.trimmed(.whitespace)
        var buffer = Buffer(raw)
        let components = try buffer.components(stem: self).map(postCompile)
        var leaf = Leaf(raw: raw.string, components: components)
        try tags.values.forEach {
            leaf = try $0.postCompile(stem: self, leaf: leaf)
        }
        return leaf
    }

    public func spawnLeaf(named name: String) throws -> Leaf {
        var name = name
        if name.hasPrefix("/") {
            name = String(name.characters.dropFirst())
        }

        // non-leaf document. rendered as pure bytes
        if name.characters.contains("."), !name.hasSuffix(".leaf") {
            if let existing = cache?[name] { return existing }
            let path = workingDirectory + name
            let bytes = try Bytes.load(path: path)
            let component = Leaf.Component.raw(bytes)
            let leaf = Leaf(raw: bytes.string, components: [component])
            cache(leaf, named: name)
            return leaf
        }

        name = name.finished(with: SUFFIX)

        // add suffix if necessary
        if let existing = cache?[name] { return existing }

        let path = workingDirectory + name
        let raw = try Bytes.load(path: path)
        let leaf = try spawnLeaf(raw: raw)
        cache(leaf, named: name)
        return leaf
    }

    private func postCompile(_ component: Leaf.Component) throws -> Leaf.Component {
        func commandPostcompile(_ tagTemplate: TagTemplate) throws -> TagTemplate {
            guard let command = tags[tagTemplate.name] else {
                throw ParseError.tagTemplateNotFound(name: tagTemplate.name)
            }
            return try command.postCompile(stem: self,
                                           tagTemplate: tagTemplate)
        }

        switch component {
        case .raw(_):
            return component
        case let .tagTemplate(tagTemplate):
            let updated = try commandPostcompile(tagTemplate)
            return .tagTemplate(updated)
        case let .chain(tagTemplates):
            let mapped = try tagTemplates.map(commandPostcompile)
            return .chain(mapped)
        }
    }
}
