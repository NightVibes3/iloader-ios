// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iloader",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "iloader", targets: ["iloader"])
    ],
    targets: [
        .target(
            name: "iloader",
            path: "iloader"
        )
    ]
)
