// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AuthService",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "AuthService",
            targets: ["AuthService"]
        ),
    ],
    dependencies: [
        .package(path: "../Models"),
        .package(path: "../SecureStorage"),
        .package(url: "https://github.com/khyeji98/SimpleNetwork.git", .upToNextMajor(from: "1.1.0")),
    ],
    targets: [
        .target(
            name: "AuthService",
            dependencies: [
                "Models",
                "SecureStorage",
                .product(name: "SimpleNetwork", package: "SimpleNetwork"),
            ]
        ),
        .testTarget(
            name: "AuthServiceTests",
            dependencies: ["AuthService"]
        ),
    ]
)
