// swift-tools-version:5.9

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
      name: "SwiftUINavigationCore",
      targets: ["SwiftUINavigationCore"]
    ),
    .library(
      name: "UIKitNavigation",
      targets: ["UIKitNavigation"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.2.2"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.1.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-perception", from: "1.1.7"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "SwiftUINavigation",
      dependencies: [
        "SwiftUINavigationCore",
        "UIKitNavigation",
        .product(name: "CasePaths", package: "swift-case-paths"),
      ]
    ),
    .testTarget(
      name: "SwiftUINavigationTests",
      dependencies: [
        "SwiftUINavigation"
      ]
    ),
    .target(
      name: "SwiftUINavigationCore",
      dependencies: [
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
      ]
    ),
    .target(
      name: "UIKitNavigation",
      dependencies: [
        "SwiftUINavigationCore",
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "Perception", package: "swift-perception"),
      ]
    ),
    .testTarget(
      name: "UIKitNavigationTests",
      dependencies: [
        "UIKitNavigation"
      ]
    ),
  ]
)
