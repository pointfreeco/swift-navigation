// swift-tools-version:5.5

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
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.6.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.5.0"),
  ],
  targets: [
    .target(
      name: "_SwiftUINavigationState",
      dependencies: [
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
      ]
    ),
    .target(
      name: "SwiftUINavigation",
      dependencies: [
        "_SwiftUINavigationState",
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
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
