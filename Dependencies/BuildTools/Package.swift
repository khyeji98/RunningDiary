// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", exact: "0.58.2"),
    ],
    targets: [
        .target(name: "BuildTools", path: "Sources"),
    ]
)
