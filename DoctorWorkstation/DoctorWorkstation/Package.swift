// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DoctorWorkstation",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-kit.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0")
    ],
    targets: [
        .executableTarget(
            name: "DoctorWorkstation",
            dependencies: [
                .product(name: "PostgresKit", package: "postgres-kit"),
                .product(name: "Crypto", package: "swift-crypto")
            ],
            path: "Sources"
        )
    ]
)
