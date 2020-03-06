import Vapor

extension Request {
    var leaf: LeafRenderer {
        .init(
            configuration: self.application.leaf.configuration,
            tags: self.application.leaf.tags,
            cache: self.application.leaf.cache,
            files: self.application.leaf.files,
            eventLoop: self.eventLoop,
            userInfo: [
                "request": self
            ]
        )
    }
}

extension LeafContext {
    public var request: Request? {
        self.userInfo["request"] as? Request
    }
}
