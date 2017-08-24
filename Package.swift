// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Leaf",
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [
        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", .branch("beta")),

        // Service container and configuration
        .package(url: "https://github.com/vapor/service.git", .branch("beta"))
    ],
    targets: [
        .target(name: "Leaf", dependencies: ["Core", "Service"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf"]),
    ]
)
