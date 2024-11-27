// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

extension Target.Dependency {
    static var argumentParser: Self {
        .product(name: "ArgumentParser", package: "swift-argument-parser")
    }
    
    static var swiftFormat: Self {
        .product(name: "SwiftFormat", package: "swift-format")
    }
}

let package = Package(
    name: "SwiftFormatLinter",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "SwiftFormatLinter",
            targets: ["SwiftFormatLinter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-format", .upToNextMajor(from: "600.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "SwiftFormatLinter",
            dependencies: [
                .argumentParser,
                .swiftFormat
            ]
        ),
        .testTarget(
            name: "SwiftFormatLinterTests",
            dependencies: ["SwiftFormatLinter"]),
    ]
)
