// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PlexusOneDesktop",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PlexusOneDesktop", targets: ["PlexusOneDesktop"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "PlexusOneDesktop",
            dependencies: ["SwiftTerm"],
            path: "Sources/PlexusOneDesktop"
        ),
        .testTarget(
            name: "PlexusOneDesktopTests",
            dependencies: ["PlexusOneDesktop"],
            path: "Tests/PlexusOneDesktopTests"
        )
    ]
)
