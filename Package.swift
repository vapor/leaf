// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Leaf",
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [
        // Swift Promises, Futures, and Streams.
        .package(url: "https://github.com/vapor/async.git", from: "1.0.0-rc"),

        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", from: "3.0.0-rc"),

        // Service container and configuration system.
        .package(url: "https://github.com/vapor/service.git", from: "1.0.0-rc"),

        // Easy-to-use foundation for building powerful templating languages in Swift.
        .package(url: "https://github.com/vapor/template-kit.git", from: "1.0.0-rc"),
    ],
    targets: [
        .target(name: "Leaf", dependencies: ["Async", "Bits", "CodableKit", "COperatingSystem", "Service", "TemplateKit"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf"]),
    ]
)
