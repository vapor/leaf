// Make this class generic w/ a `tag` that is automatically injected. 
// Infinite args, ie: @p("class='asdf'", ...) { }
public final class HTML: Tag {
    public let name = "html"

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Any? {
        guard arguments.isEmpty else { throw "h1 supports no arguments" }
        return nil
    }

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument], value: Any?) -> Bool {
        return true
    }

    public func render(stem: Stem, context: Context, value: Any?, leaf: Leaf) throws -> Bytes {
        var buffer = "\n<html>\n".bytes
        buffer += try stem.render(leaf, with: context)
        buffer += "\n</html>\n".bytes
        return buffer
    }
}

public final class H1: Tag {
    public let name = "h1"

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Any? {
        guard arguments.isEmpty else { throw "h1 supports no arguments" }
        return nil
    }

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument], value: Any?) -> Bool {
        return true
    }

    public func render(stem: Stem, context: Context, value: Any?, leaf: Leaf) throws -> Bytes {
        var buffer = "\n<h1>".bytes
        buffer += try stem.render(leaf, with: context)
        buffer += "</h1>\n".bytes
        return buffer
    }
}

public final class Body: Tag {
    public let name = "body"

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Any? {
        guard arguments.isEmpty else { throw "h1 supports no arguments" }
        return nil
    }

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument], value: Any?) -> Bool {
        return true
    }

    public func render(stem: Stem, context: Context, value: Any?, leaf: Leaf) throws -> Bytes {
        var buffer = "\n<body>\n".bytes
        buffer += try stem.render(leaf, with: context)
        buffer += "\n</body>\n".bytes
        return buffer
    }
}

public final class Head: Tag {
    public let name = "head"

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Any? {
        guard arguments.isEmpty else { throw "h1 supports no arguments" }
        return nil
    }

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument], value: Any?) -> Bool {
        return true
    }

    public func render(stem: Stem, context: Context, value: Any?, leaf: Leaf) throws -> Bytes {
        var buffer = "\n<head>\n".bytes
        buffer += try stem.render(leaf, with: context)
        buffer += "\n</head>\n".bytes
        return buffer
    }
}


public final class Div: Tag {
    public let name = "div"

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Any? {
        guard arguments.count == 1 else {
            throw "div expects single argument, class"
        }
        switch arguments[0] {
        case let .constant(value: value):
            return value
        case let .variable(key: _, value: value):
            return value
        }
    }

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument], value: Any?) -> Bool {
        return true
    }

    public func render(stem: Stem, context: Context, value: Any?, leaf: Leaf) throws -> Bytes {
        guard let classname = value as? String else {
            throw "invalid value: \(value), expected String"
        }

        var buffer = "\n<div class=\"\(classname)\">\n".bytes
        buffer += try stem.render(leaf, with: context)
        buffer += "\n</div>\n".bytes
        return buffer
    }
}
