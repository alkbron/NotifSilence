// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotifSilence",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "NotifSilence", path: "Sources/NotifSilence")
    ]
)
