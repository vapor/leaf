import Vapor

extension Request {
    public var leaf: LeafRenderer {
        var userInfo = self.application.leaf.userInfo
        userInfo["request"] = self
        userInfo["application"] = self.application

        return .init(
            configuration: self.application.leaf.configuration,
            tags: self.application.leaf.tags,
            cache: self.application.leaf.cache,
            files: self.application.leaf.files,
            eventLoop: self.eventLoop,
            userInfo: userInfo
        )
    }
}

extension LeafContext {
    public var request: Request? {
        self.userInfo["request"] as? Request
    }
}
