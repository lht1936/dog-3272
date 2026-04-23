// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "NetworkTrafficMonitor",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "NetworkTrafficMonitor",
            targets: ["NetworkTrafficMonitor"]
        )
    ],
    targets: [
        .executableTarget(
            name: "NetworkTrafficMonitor",
            path: "NetworkTrafficMonitor"
        )
    ]
)
