// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PersistencesService",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "PersistencesService",
            targets: ["PersistencesService"]
        ),
    ],
    dependencies: [
        .package(path: "../Models")
    ],
    targets: [
        .target(
            name: "PersistencesService",
            dependencies: ["Models"]
        ),
        .testTarget(
            name: "PersistencesServiceTests",
            dependencies: ["PersistencesService"]
        ),
    ]
)
