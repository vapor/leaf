import PackageDescription

let package = Package(
    name: "Leaf",
    dependencies: [
        .Package(url: "https://github.com/vapor/core.git", majorVersion: 0, minor: 5),
        .Package(url: "https://github.com/vapor/node.git", majorVersion: 0, minor: 6)
    ]
)
