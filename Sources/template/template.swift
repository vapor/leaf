/*
     // TODO: GLOBAL
     - Filters/Modifiers are supported longform, consider implementing short form -> Possibly compile out to longform
         `@(foo.bar()` == `@bar(foo)`
         `@(foo.bar().waa())` == `@bar(foo) { @waa(self) }`
     - Extendible Leafs
     - Allow no argument tags to terminate with a space, ie: @h1 {` or `@date`
     - HTML Tags, a la @h1() { }
     - Dynamic Tag w/ (Any?) throws? -> Any?
*/
import Core
import Foundation

var workDir: String {
    let parent = #file.characters.split(separator: "/").map(String.init).dropLast().joined(separator: "/")
    let path = "/\(parent)/../../Resources/"
    return path
}

func loadLeaf(named name: String) throws -> Leaf {
    let stem = Stem()
    let template = try stem.loadLeaf(named: name)
    return template
}

func load(path: String) throws -> Bytes {
    guard let data = NSData(contentsOfFile: path) else {
        throw "unable to load bytes"
    }
    var bytes = Bytes(repeating: 0, count: data.length)
    data.getBytes(&bytes, length: bytes.count)
    return bytes
}


// TODO: Should optional be renderable, and render underlying?
protocol Renderable {
    func rendered() throws -> Bytes
}

extension Stem {
    func render(_ leaf: Leaf, with filler: Scope) throws -> Bytes {
        let stem = self
        let initialQueue = filler.queue
        defer { filler.queue = initialQueue }

        var buffer = Bytes()
        try leaf.components.forEach { component in
            switch component {
            case let .raw(bytes):
                buffer += bytes
            case let .tagTemplate(tagTemplate):
                guard let command = stem.tags[tagTemplate.name] else { throw "unsupported tagTemplate" }
                let arguments = try command.makeArguments(
                    stem: stem,
                    filler: filler,
                    tagTemplate: tagTemplate
                )

                let value = try command.run(stem: stem, filler: filler, tagTemplate: tagTemplate, arguments: arguments)
                let shouldRender = command.shouldRender(
                    stem: stem,
                    filler: filler,
                    tagTemplate: tagTemplate,
                    arguments: arguments,
                    value: value
                )
                guard shouldRender else { return }

                switch value {
                    /**
                     ** Warning **
                     MUST parse out non-optional explicitly to
                     avoid printing strings as `Optional(string)`
                     */
                case let val?:
                    filler.push(["self": val])
                default:
                    filler.push(["self": value])
                }

                if let subtemplate = tagTemplate.body {
                    buffer += try command.render(stem: stem, filler: filler, value: value, template: subtemplate)
                } else if let rendered = try filler.renderedSelf() {
                    buffer += rendered
                }
            case let .chain(chain):
                /**
                 *********************
                 ****** WARNING ******
                 *********************

                 Deceptively similar to above, nuance will break e'rything!
                 **/
                print("Chain: \n\(chain.map { "\($0)" } .joined(separator: "\n"))")
                for tagTemplate in chain {
                    // TODO: Copy pasta, clean up
                    guard let command = stem.tags[tagTemplate.name] else { throw "unsupported tagTemplate" }
                    let arguments = try command.makeArguments(
                        stem: stem,
                        filler: filler,
                        tagTemplate: tagTemplate
                    )

                    let value = try command.run(stem: stem, filler: filler, tagTemplate: tagTemplate, arguments: arguments)
                    let shouldRender = command.shouldRender(
                        stem: stem,
                        filler: filler,
                        tagTemplate: tagTemplate,
                        arguments: arguments,
                        value: value
                    )
                    guard shouldRender else {
                        // ** WARNING **//
                        continue
                    }

                    switch value {
                        /**
                         ** Warning **
                         MUST parse out non-optional explicitly to
                         avoid printing strings as `Optional(string)`
                         */
                    case let val?:
                        filler.push(["self": val])
                    default:
                        filler.push(["self": value])
                    }

                    if let subtemplate = tagTemplate.body {
                        buffer += try command.render(stem: stem, filler: filler, value: value, template: subtemplate)
                    } else if let rendered = try filler.renderedSelf() {
                        buffer += rendered
                    }

                    // NECESSARY TO POP!
                    filler.pop()
                    return // Once a link in the chain is marked as pass (shouldRender), break scope
                }
            }
        }
        return buffer
    }
}

