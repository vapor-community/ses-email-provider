// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "ses-email-provider",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "SESEmailProvider", targets: ["SESEmailProvider"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/email.git", branch: "api"),
        .package(url: "https://github.com/soto-project/soto.git", from: "6.0.0"),
    ],
    targets: [
        .target(
            name: "SESEmailProvider",
            dependencies: [
                .product(name: "Email", package: "email"),
                .product(name: "SotoSES", package: "soto"),
            ]),
        .testTarget(
            name: "SESEmailProviderTests",
            dependencies: ["SESEmailProvider"]),
    ]
)
