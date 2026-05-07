// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WeaveFFIImageDemo",
    platforms: [
        .macOS(.v11),
    ],
    targets: [
        .systemLibrary(name: "CWeaveFFI"),
        .executableTarget(
            name: "demo",
            dependencies: ["CWeaveFFI"]
        ),
    ]
)
