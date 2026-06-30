// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CannedFruitsNative",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CannedFruitsNative", targets: ["CannedFruitsNative"])
    ],
    targets: [
        .executableTarget(name: "CannedFruitsNative")
    ]
)
