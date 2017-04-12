extension Stem {
    public func spawnLeaf(raw: String) throws -> Leaf {
        return try spawnLeaf(raw: raw.makeBytes())
    }

    public func spawnLeaf(raw: Bytes) throws -> Leaf {
        let raw = raw.trimmed(.whitespace)
        var buffer = Buffer(raw)
        let components = try buffer.components(stem: self).map(postCompile)
        var leaf = Leaf(raw: raw.makeString(), components: components)
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
        return try spawnLeaf(at: workingDirectory + name)
    }
    
    public func spawnLeaf(at path: String) throws -> Leaf {
        if let existing = cache?[path] {
            return existing
        }
        
        let leaf: Leaf
        
        // non-leaf document. rendered as pure bytes
        if path.components(separatedBy: "/").last?.contains(".") == true, !path.hasSuffix(".leaf") {
            let bytes = try Bytes.load(path: path)
            let component = Leaf.Component.raw(bytes)
            leaf = Leaf(raw: bytes.makeString(), components: [component])
        } else {
            // add suffix if necessary
            var path = path
            path = path.finished(with: SUFFIX)
            
            let raw = try Bytes.load(path: path)
            leaf = try spawnLeaf(raw: raw)
        }
        
        cache(leaf, named: path)
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
