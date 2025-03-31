// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GameOfStones",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "GameOfStones", targets: ["GameOfStones"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "GameOfStones"),
        .testTarget(
            name: "GameOfStonesTests",
            dependencies: [
                "GameOfStones",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)
