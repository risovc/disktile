// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DiskTile",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "DiskTile",
            targets: ["DiskTile"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DiskTile",
            dependencies: [],
            path: "Sources/DiskTile",
            resources: []
        )
    ]
)
