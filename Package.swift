// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "heic",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "heic",
            resources: [.copy("heic.plist")]
				)
    ]
)
