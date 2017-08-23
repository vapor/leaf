// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Leaf",
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [
        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", .branch("beta"))
    ],
    targets: [
        .target(name: "Leaf", dependencies: ["Core"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf"]),
    ]
)
