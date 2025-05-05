// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GameOfStones",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "Heap", targets: ["Heap"]),
        .library(name: "Tree", targets: ["Tree"]),
        .library(name: "Board", targets: ["Board"]),
        .executable(name: "HeapBench", targets: ["HeapBench"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", branch: "main")
    ],
    targets: [
        .target(name: "Heap"),
        .target(name: "Tree"),
        .target(name: "Board"),
        .executableTarget(name: "HeapBench", dependencies: ["Heap"]),
        .testTarget(
            name: "BenchTests",
            dependencies: [
                "Heap",
                "Tree",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)
