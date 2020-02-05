// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "leaf",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/leaf-kit.git", from:"1.0.0-beta.2.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.2"),
    ],
    targets: [
        .target(name: "Leaf", dependencies: ["LeafKit", "Vapor"]),
        .testTarget(name: "LeafTests", dependencies: ["Leaf", "XCTVapor"]),
    ]
)
