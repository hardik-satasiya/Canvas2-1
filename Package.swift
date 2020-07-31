// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Canvas2",
    platforms:[.macOS(.v10_10)],
    products: [.library(name: "Canvas2", targets: ["Canvas2"]),],
    targets: [
        .target(name: "Canvas2", dependencies: [], path: "Sources"),
        .testTarget(name: "Canvas2Tests", dependencies: ["Canvas2"]),
    ]
)
