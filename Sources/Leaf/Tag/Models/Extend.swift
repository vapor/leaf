public final class Extend: Tag {
    public enum Error: LeafError {
        case expectedSingleArgument(have: [Argument])
    }

    public let name = "extend"

    public func postCompile(
        stem: Stem,
        leaf: Leaf
    ) throws -> Leaf {
        guard leaf.isExtension else { return leaf }
        let base = try stem.loadExtensionBase(for: leaf)
        return base.exchangeImports(exporting: leaf)
    }

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]
    ) throws -> Node? {
        return nil
    }
}

extension Leaf {
    func exchangeImports(exporting: Leaf) -> Leaf {
        let exports = exporting.gatherExports()

        var comps: [Leaf.Component] = []
        components.forEach { component in
            guard case let .tagTemplate(template) = component, template.name == "import" else {
                comps.append(component)
                return
            }

            template.parameters.first?.constant.flatMap { importName in
                if let exported = exports[importName] {
                    comps += exported.components.array
                } else if let fallback = template.body {
                    comps += fallback.components.array
                }
            }
        }

        return Leaf(raw: exporting.raw, components: comps)
    }
}

extension Stem {
    func loadExtensionBase(for leaf: Leaf) throws -> Leaf {
        guard
            let tip = leaf.components.tip?.value,
            case let .tagTemplate(template) = tip,
            template.name == "extend",
            let name = template.parameters.first?.constant
            else { return leaf }
        return try spawnLeaf(named: name)
    }
}

extension Leaf {
    internal var isExtension: Bool {
        guard let tip = components.tip?.value, case let .tagTemplate(template) = tip else { return false }
        return template.name == "extend"
    }

    internal func gatherExports() -> [String: Leaf] {
        var imports: [String: Leaf] = [:]
        components.forEach { component in
            guard
                case let .tagTemplate(template) = component, template.name == "export",
                let constant = template.parameters.first?.constant
                else { return }
            imports[constant] = template.body
        }
        return imports
    }
}

extension Parameter {
    var constant: String? {
        guard case let .constant(val) = self else { return nil }
        return val
    }
}
