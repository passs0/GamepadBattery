// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GamepadBattery",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "GamepadBattery",
            targets: ["GamepadBattery"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "GamepadBattery",
            path: "Sources/GamepadBattery"
        ),
    ]
)
