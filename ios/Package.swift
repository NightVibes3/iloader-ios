// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "iloader",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(name: "iloader", targets: ["iloader"])
    ],
    targets: [
        .executableTarget(
            name: "iloader",
            path: "iloader"
        )
    ]
)
