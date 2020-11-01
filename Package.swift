// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "leaf",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Leaf", targets: ["Leaf"]),
    ],
    dependencies: [
        .package(name: "leaf-kit", url: "https://github.com/tdotclare/leaf-kit.git", .branch("Tau")),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "Leaf", dependencies: [
            .product(name: "LeafKit", package: "leaf-kit"),
            .product(name: "Vapor", package: "vapor"),
        ]),
        .testTarget(name: "LeafTests", dependencies: [
            .target(name: "Leaf"),
            .product(name: "XCTVapor", package: "vapor"),
            .product(name: "XCTLeafKit", package: "leaf-kit")
        ]),
    ]
)
