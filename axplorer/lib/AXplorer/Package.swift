// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AXplorer",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "AXplorer",
            type: .dynamic,
            targets: ["AXplorer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "AXplorer",
            dependencies: ["Yams"]),
        .testTarget(
            name: "AXplorerTests",
            dependencies: ["AXplorer"])
    ]
)
