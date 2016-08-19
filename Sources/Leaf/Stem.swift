private var workDir: String {
    let parent = #file.characters.split(separator: "/").map(String.init).dropLast().joined(separator: "/")
    let path = "/\(parent)/../../Resources/"
    return path
}

public class Stem {
    public let workingDirectory: String
    public private(set) var tags: [String: Tag] = defaultTags
    public private(set) var cache: [String: Leaf] = [:]

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
    public func spawnLeaf(raw: String) throws -> Leaf {
        return try spawnLeaf(raw: raw.bytes)
    }

    public func spawnLeaf(raw: Bytes) throws -> Leaf {
        let raw = raw.trimmed(.whitespace)
        var buffer = Buffer(raw)
        let components = try buffer.components().map(postCompile)
        let leaf = Leaf(raw: raw.string, components: components)
        return leaf
    }

    public func spawnLeaf(named name: String) throws -> Leaf {
        if let existing = cache[name] { return existing }

        var subpath = name.finished(with: SUFFIX)
        if subpath.hasPrefix("/") {
            subpath = String(subpath.characters.dropFirst())
        }
        let path = workingDirectory + subpath

        let raw = try Bytes.load(path: path)
        let leaf = try spawnLeaf(raw: raw)
        cache[name] = leaf
        return leaf
    }

    private func postCompile(_ component: Leaf.Component) throws -> Leaf.Component {
        func commandPostcompile(_ tagTemplate: TagTemplate) throws -> TagTemplate {
            guard let command = tags[tagTemplate.name] else { throw "unsupported tagTemplate: \(tagTemplate.name)"
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
