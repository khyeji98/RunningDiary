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
    dependencies: [
        .package(url: "https://github.com/khyeji98/SimpleNetwork.git", exact: "1.0.0")
    ],
    targets: [
        .target(
            name: "CoreNetwork",
            dependencies: ["SimpleNetwork"]
        ),
        .testTarget(
            name: "CoreNetworkTests",
            dependencies: ["CoreNetwork"]
        ),
    ]
)
