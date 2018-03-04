// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Leaf",
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [
        // 🌎 Utility package containing tools for byte manipulation, Codable, OS APIs, and debugging.
        .package(url: "https://github.com/vapor/core.git", .branch("nio")),

        // 📦 Dependency injection / inversion of control framework.
        .package(url: "https://github.com/vapor/service.git", .branch("nio")),

        // 📄 Easy-to-use foundation for building powerful templating languages in Swift.
        .package(url: "https://github.com/vapor/template-kit.git", .branch("nio")),
    ],
    targets: [
        .target(name: "Leaf", dependencies: ["Async", "Bits", "CodableKit", "COperatingSystem", "Service", "TemplateKit"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf"]),
    ]
)
