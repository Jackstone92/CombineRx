// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineRx",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        .library(
            name: "CombineRx",
            targets: ["CombineRx"]
        ),
    ],
    dependencies: [
        .package(url: "http://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/pointfreeco/combine-schedulers", .upToNextMajor(from: "0.5.3"))
    ],
    targets: [
        .target(
            name: "CombineRx",
            dependencies: ["RxSwift"]
        ),
        .testTarget(
            name: "CombineRxTests",
            dependencies: [
                "CombineRx",
                .product(name: "RxTest", package: "RxSwift"),
                .product(name: "CombineSchedulers", package: "combine-schedulers")
            ]
        )
    ]
)
