// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Soundable",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "Soundable", targets: ["Soundable"])
    ],
    targets: [
        .target(
            name: "Soundable",
            path: "Source",
            exclude: ["Info.plist", "Soundable.h"]
        ),
        .testTarget(
            name: "SoundableTests",
            dependencies: ["Soundable"],
            path: "Tests",
            exclude: ["Info.plist"]
        )
    ],
    swiftLanguageModes: [.v6]
)
