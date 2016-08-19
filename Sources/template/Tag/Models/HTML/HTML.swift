public final class HTML: Tag {
    public let name = "html"

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument], value: Any?) -> Bool {
        return true
    }

    public func render(stem: Stem, context: Context, value: Any?, leaf: Leaf) throws -> Bytes {
        var buffer = "<html>".bytes
        buffer += try stem.render(leaf, with: context)
        buffer += "</html>".bytes
        return buffer
    }
}

public final class Body: Tag {
    public let name = "body"

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument], value: Any?) -> Bool {
        return true
    }

    public func render(stem: Stem, context: Context, value: Any?, leaf: Leaf) throws -> Bytes {
        var buffer = "<body>".bytes
        buffer += try stem.render(leaf, with: context)
        buffer += "</body>".bytes
        return buffer
    }
}

public final class Head: Tag {
    public let name = "head"


    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument], value: Any?) -> Bool {
        return true
    }

    public func render(stem: Stem, context: Context, value: Any?, leaf: Leaf) throws -> Bytes {
        var buffer = "<head>".bytes
        buffer += try stem.render(leaf, with: context)
        buffer += "</head>".bytes
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

        var buffer = "<div class=\"\(classname)\">".bytes
        buffer += try stem.render(leaf, with: context)
        buffer += "</head>".bytes
        return buffer
    }
}
