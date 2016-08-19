import Core

public class Stem {
    public let workingDirectory: String
    public private(set) var tags: [String: Tag] = defaultTags

    public init(workingDirectory: String = workDir) {
        self.workingDirectory = workingDirectory.finished(with: "/")
    }
}

extension Stem {
    public func register(tag: Tag) {
        tags[tag.name] = tag
    }
}


extension Stem {
    public func loadLeaf(raw: String) throws -> Leaf {
        return try loadLeaf(raw: raw.bytes)
    }

    public func loadLeaf(raw: Bytes) throws -> Leaf {
        let raw = raw.trimmed(.whitespace)
        var buffer = Buffer(raw)
        let components = try buffer.components().map(postCompile)
        let template = Leaf(raw: raw.string, components: components)
        return template
    }

    public func loadLeaf(named name: String) throws -> Leaf {
        var subpath = name.finished(with: SUFFIX)
        if subpath.hasPrefix("/") {
            subpath = String(subpath.characters.dropFirst())
        }
        let path = workingDirectory + subpath

        let raw = try load(path: path)
        return try loadLeaf(raw: raw)
    }

    private func postCompile(_ component: Leaf.Component) throws -> Leaf.Component {
        func commandPostcompile(_ tagTemplate: TagTemplate) throws -> TagTemplate {
            guard let command = tags[tagTemplate.name] else { throw "unsupported tagTemplate: \(tagTemplate.name)" }
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
