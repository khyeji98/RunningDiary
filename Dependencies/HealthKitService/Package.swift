// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HealthKitService",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "HealthKitService",
            targets: ["HealthKitService"]
        ),
    ],
    dependencies: [
        .package(path: "../Models"),
        .package(path: "../CommonFoundation"),
    ],
    targets: [
        .target(
            name: "HealthKitService",
            dependencies: ["Models", "CommonFoundation"]
        ),
        .testTarget(
            name: "HealthKitServiceTests",
            dependencies: ["HealthKitService"]
        ),
    ]
)
