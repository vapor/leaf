import Core

protocol Tag {
    var name: String { get }

    // after a template is compiled, an tagTemplate will be passed in for validation/modification if necessary
    func postCompile(stem: Stem,
                     tagTemplate: TagTemplate) throws -> TagTemplate

    // turn parameters in template into concrete arguments
    func makeArguments(stem: Stem,
                       filler: Scope,
                       tagTemplate: TagTemplate) throws -> [Argument]


    // run the tag w/ the specified arguments and returns the value to add to scope or render
    func run(stem: Stem, filler: Scope, tagTemplate: TagTemplate, arguments: [Argument]) throws -> Any?

    // whether or not the given value should be rendered. Defaults to `!= nil`
    func shouldRender(stem: Stem, filler: Scope, tagTemplate: TagTemplate, arguments: [Argument], value: Any?) -> Bool

    // filler is populated with value at this point
    // renders a given template, can override for custom behavior. For example, #loop
    func render(stem: Stem, filler: Scope, value: Any?, template: Leaf) throws -> Bytes
}

extension Tag {
    func postCompile(stem: Stem,
                     tagTemplate: TagTemplate) throws -> TagTemplate {
        return tagTemplate
    }

    func makeArguments(stem: Stem,
                       filler: Scope,
                       tagTemplate: TagTemplate) throws -> [Argument]{
        return tagTemplate.makeArguments(filler: filler)
    }

    func run(stem: Stem, filler: Scope, tagTemplate: TagTemplate, arguments: [Argument]) throws -> Any? {
        guard arguments.count == 1 else {
            throw "more than one argument not supported, override \(#function) for custom behavior"
        }

        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            return value
        case let .variable(key: _, value: value):
            return value
        }
    }

    func shouldRender(stem: Stem,
                      filler: Scope,
                      tagTemplate: TagTemplate,
                      arguments: [Argument],
                      value: Any?) -> Bool {
        return value != nil
    }

    func render(stem: Stem,
                filler: Scope,
                value: Any?,
                template: Leaf) throws -> Bytes {
        return try template.render(in: stem, with: filler)
    }
}
