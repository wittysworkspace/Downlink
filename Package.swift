// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Downlink",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Downlink", targets: ["Downlink"])
    ],
    targets: [
        .executableTarget(
            name: "Downlink",
            path: "Sources/Downlink"
        )
    ]
)
