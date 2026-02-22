// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkService",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "NetworkService",
            targets: ["NetworkService"]),
    ],
    dependencies: [
        .package(url: "https://github.com/khyeji98/SimpleNetwork.git", exact: "1.0.0"),
        .package(path: "../Models")
    ],
    targets: [
        .target(
            name: "NetworkService",
            dependencies: [
                "SimpleNetwork",
                "Models"
            ]
        )
    ]
)
