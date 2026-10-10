// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IlyasTV",
    defaultLocalization: "tr",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "IlyasTVCore",
            targets: ["IlyasTVCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "IlyasTVCore",
            path: "IlyasTV/Sources"
        )
    ]
)
