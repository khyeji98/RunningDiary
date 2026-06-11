// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreNetwork",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "CoreNetwork",
            targets: ["CoreNetwork"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CoreNetwork"
        ),
    ]
)
