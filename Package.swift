// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Leaf",
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/bits.git", from: "1.1.0"),
    ],
    targets: [
        .target(name: "Leaf", dependencies: ["Bits"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf"]),
    ]
)
