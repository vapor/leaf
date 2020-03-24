import Vapor

extension Request {
    var leaf: LeafRenderer {
        self.application.leaf.userInfo["request"] = self
        self.application.leaf.userInfo["application"] = self.application
        
        return .init(
            configuration: self.application.leaf.configuration,
            tags: self.application.leaf.tags,
            cache: self.application.leaf.cache,
            files: self.application.leaf.files,
            eventLoop: self.eventLoop,
            userInfo: self.application.leaf.userInfo
        )
    }
}

extension LeafContext {
    public var request: Request? {
        self.userInfo["request"] as? Request
    }
}
