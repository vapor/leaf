import Async
import Dispatch
import Foundation
import TemplateKit

/// Serializes parsed Leaf ASTs into view bytes.
public final class LeafSerializer: TemplateSerializer {
    public let ast: [TemplateSyntax]
    public var context: TemplateContext
    public let eventLoop: EventLoop
    public let renderer: LeafRenderer

    /// Creates a new Serializer.
    public init(ast: [TemplateSyntax], renderer: LeafRenderer,  context: TemplateContext, on worker: Worker) {
        self.ast = ast
        self.context = context
        self.renderer = renderer
        self.eventLoop = worker.eventLoop
    }

    /// See TemplateSerializer.render
    public func render(tag parsed: TemplateTag) -> Future<TemplateData> {
        return Future {
            guard let tag = self.renderer.tags[parsed.name] else {
                /// FIXME: throw
                fatalError()
            }

            return try tag.render(
                parsed: parsed,
                context: self.context,
                renderer: self.renderer
            )
        }
    }

    /// See TemplateSerializer.subSerializer
    public func subSerializer(for ast: [TemplateSyntax]) -> LeafSerializer {
        return LeafSerializer(ast: ast, renderer: renderer, context: context, on: self)
    }
}

