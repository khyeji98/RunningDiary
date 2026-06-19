// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SecureStorage",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "SecureStorage",
            targets: ["SecureStorage"]
        ),
    ],
    targets: [
        .target(
            name: "SecureStorage"
        ),
        .testTarget(
            name: "SecureStorageTests",
            dependencies: ["SecureStorage"]
        ),
    ]
)
