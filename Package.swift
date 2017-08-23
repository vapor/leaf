// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Leaf",
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/core.git", .branch("bytes"))
    ],
    targets: [
        .target(name: "Leaf", dependencies: ["Core"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf"]),
    ]
)
