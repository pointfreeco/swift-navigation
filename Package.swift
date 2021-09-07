// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "swiftui-navigation",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "SwiftUINavigation",
      targets: ["SwiftUINavigation"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.7.0")
  ],
  targets: [
    .target(
      name: "SwiftUINavigation",
      dependencies: [
        .product(name: "CasePaths", package: "swift-case-paths")
      ]
    ),
    .testTarget(
      name: "SwiftUINavigationTests",
      dependencies: [
        "SwiftUINavigation"
      ]
    ),
  ]
)
