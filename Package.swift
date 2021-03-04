// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineRx",
    platforms: [
        .macOS(.v10_15), .iOS(.v13)
    ],
    products: [
        .library(name: "CombineRx",
                 targets: ["CombineRxInteroperability", "CombineRxUtility"]),
        .library(name: "CombineRxInteroperability",
                 targets: ["CombineRxInteroperability"]),
        .library(name: "CombineRxUtility",
                 targets: ["CombineRxUtility"])
    ],
    dependencies: [
        .package(url: "http://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/pointfreeco/combine-schedulers", .upToNextMajor(from: "0.1.2"))
    ],
    targets: [
        .target(name: "CombineRxInteroperability",
                dependencies: ["RxSwift"]),
        .target(name: "CombineRxUtility",
                dependencies: []),

        // MARK: - Tests
        .target(name: "TestCommon", path: "Tests/Common"),
        .testTarget(name: "CombineRxInteroperabilityTests",
                    dependencies: ["CombineRxInteroperability",
                                   "TestCommon",
                                   .product(name: "RxTest", package: "RxSwift"),
                                   .product(name: "CombineSchedulers", package: "combine-schedulers")]),
        .testTarget(name: "CombineRxUtilityTests",
                    dependencies: ["CombineRxUtility",
                                   "TestCommon",
                                   .product(name: "CombineSchedulers", package: "combine-schedulers")]),
    ]
)
