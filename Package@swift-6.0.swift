// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  // NB: Keep this for backwards compatibility. Will rename to 'swift-navigation' in 2.0.
  name: "swiftui-navigation",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "SwiftNavigation",
      targets: ["SwiftNavigation"]
    ),
    .library(
      name: "SwiftUINavigation",
      targets: ["SwiftUINavigation"]
    ),
    // TODO: Should this be reorganized and renamed to `SwiftNavigationState`?
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
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.5.3"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.1.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.1"),
    .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "1.2.0"),
    .package(url: "https://github.com/pointfreeco/swift-perception", from: "1.3.3"),
  ],
  targets: [
    .target(
      name: "SwiftNavigation",
      dependencies: [
        "SwiftUINavigationCore",
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "Perception", package: "swift-perception"),
      ]
    ),
    .target(
      name: "SwiftUINavigation",
      dependencies: [
        "SwiftUINavigationCore",
        "UIKitNavigation",
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
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
        .product(name: "IssueReporting", package: "swift-issue-reporting"),
      ]
    ),
    .target(
      name: "UIKitNavigation",
      dependencies: [
        "SwiftNavigation",
        "SwiftUINavigationCore",
        "UIKitNavigationShim",
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
      ]
    ),
    .target(
      name: "UIKitNavigationShim"
    ),
    .testTarget(
      name: "UIKitNavigationTests",
      dependencies: [
        "UIKitNavigation"
      ]
    ),
  ],
  swiftLanguageVersions: [.v6]
)
