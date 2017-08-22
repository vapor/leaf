// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Leaf",
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Leaf", dependencies: []),
        .testTarget(name: "LeafTests", dependencies: ["Leaf"]),
    ]
)
