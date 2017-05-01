import PackageDescription

let beta = Version(2,0,0, prereleaseIdentifiers: ["beta"])

let package = Package(
    name: "Leaf",
    dependencies: [
        .Package(url: "https://github.com/vapor/core.git", Version(0,0,0)),
        .Package(url: "https://github.com/vapor/node.git", beta),
    ]
)
