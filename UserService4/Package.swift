// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "UserService",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(name: "Run", targets: ["Run"]),
        .library(name: "App", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/vapor/open-crypto", from: "4.0.0-alpha.2"),
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0-beta"),
        .package(url: "https://github.com/skelpo/sendgrid-provider.git", .branch("master")),
        .package(url: "https://github.com/vapor/jwt-kit", .branch("master"))
    ],
    targets: [
        .target(name: "App", dependencies: ["Fluent", "OpenCrypto", "SendGrid", "FluentMySQLDriver", "JWTKit",  "Vapor"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
