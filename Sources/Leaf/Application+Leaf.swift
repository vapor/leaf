import Vapor

extension Application.Views.Provider {
    public static var leaf: Self {
        .init {
            $0.views.use {
                $0.leaf.renderer
            }
        }
    }
}

extension Application {
    public var leaf: Leaf {
        .init(application: self)
    }

    public struct Leaf {
        public let application: Application

        public var renderer: LeafRenderer {
            .init(
                configuration: self.configuration,
                cache: self.cache,
                files: self.files,
                eventLoop: self.application.eventLoopGroup.next(),
                userInfo: [
                    "application": self
                ]
            )
        }

        public var configuration: LeafConfiguration {
            get {
                self.storage.configuration ?? LeafConfiguration(
                    rootDirectory: self.application.directory.viewsDirectory
                )
            }
            nonmutating set {
                self.storage.configuration = newValue
            }
        }

        public var tags: [String: LeafTag] {
            get {
                self.storage.tags
            }
            nonmutating set {
                self.storage.tags = newValue
            }
        }

        public var files: LeafFiles {
            get {
                self.storage.files ?? NIOLeafFiles(fileio: self.application.fileio)
            }
            nonmutating set {
                self.storage.files = newValue
            }
        }

        public var cache: LeafCache {
            get {
                self.storage.cache
            }
            nonmutating set {
                self.storage.cache = newValue
            }
        }

        var storage: Storage {
            if let existing = self.application.storage[Key.self] {
                return existing
            } else {
                let new = Storage()
                self.application.storage[Key.self] = new
                return new
            }
        }

        struct Key: StorageKey {
            typealias Value = Storage
        }

        final class Storage {
            var cache: LeafCache
            var configuration: LeafConfiguration?
            var files: LeafFiles?
            var tags: [String: LeafTag]

            init() {
                self.cache = DefaultLeafCache()
                self.tags = LeafKit.defaultTags
            }
        }
    }
}


extension LeafContext {
    public var application: Application? {
        self.userInfo["application"] as? Application
    }
}
