// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Leaf",
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
        .library(name: "TemplateKit", targets: ["TemplateKit"]),
    ],
    dependencies: [
        // Swift Promises, Futures, and Streams.
        .package(url: "https://github.com/vapor/async.git", .branch("beta")),

        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", .branch("beta")),

        // Service container and configuration system.
        .package(url: "https://github.com/vapor/service.git", .branch("beta")),
    ],
    targets: [
        .target(name: "Leaf", dependencies: ["Async", "Bits", "CodableKit", "COperatingSystem", "Service", "TemplateKit"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf"]),
        .target(name: "TemplateKit", dependencies: ["Async", "Bits", "CodableKit"]),
    ]
)
