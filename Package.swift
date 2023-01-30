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
    ),
    .library(
      name: "_SwiftUINavigationState",
      targets: ["_SwiftUINavigationState"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.11.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.6.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.8.0"),
  ],
  targets: [
    .target(
      name: "_SwiftUINavigationState",
      dependencies: [
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
      ]
    ),
    .target(
      name: "SwiftUINavigation",
      dependencies: [
        "_SwiftUINavigationState",
        .product(name: "CasePaths", package: "swift-case-paths"),
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
