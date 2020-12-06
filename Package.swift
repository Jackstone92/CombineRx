// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineRxBridge",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        .library(
            name: "CombineRxBridge",
            targets: ["CombineRxBridge"]),
    ],
    dependencies: [
        .package(url: "http://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.0")),
    ],
    targets: [
        .target(
            name: "CombineRxBridge",
            dependencies: ["RxSwift"]),
        .testTarget(
            name: "CombineRxBridgeTests",
            dependencies: ["CombineRxBridge",
                           .product(name: "RxTest", package: "RxSwift")])
    ]
)
