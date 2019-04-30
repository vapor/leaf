// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "leaf",
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/leaf-kit.git", .branch("master")),
        .package(url: "https://github.com/vapor/vapor.git", .branch("master")),
    ],
    targets: [
        .target(name: "Leaf", dependencies: ["LeafKit", "Vapor"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf"]),
    ]
)
