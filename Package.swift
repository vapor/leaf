import PackageDescription

let package = Package(
    name: "Leaf",
    dependencies: [
      .Package(url: "https://github.com/vapor/node.git", majorVersion: 0)
      .Package(url: "https://github.com/zewo/mustache.git", majorVersion: 0)
    ]
)
