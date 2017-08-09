// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Leaf",
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/bits.git", from: "1.1.0"),
        .package(url: "https://github.com/vapor/mapper.git", .branch("beta")),

    ],
    targets: [
        .target(name: "Leaf", dependencies: ["Bits", "Mapper"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf"]),
    ]
)
