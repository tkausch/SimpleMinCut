// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SimpleMinCut",
    products: [
        .library(name: "SimpleMinCut", targets: ["SimpleMinCut"]),
        .executable(name: "simple-mincut", targets: ["simple-mincut-cli"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .target(name: "SimpleMinCut"),
        .executableTarget(
            name: "simple-mincut-cli",
            dependencies: [
                "SimpleMinCut",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "SimpleMinCutTests",
            dependencies: ["SimpleMinCut"]
        ),
    ]
)
