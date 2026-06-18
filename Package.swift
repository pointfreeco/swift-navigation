// swift-tools-version: 6.1

import CompilerPluginSupport
import PackageDescription

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

let package = Package(
  name: "swift-navigation",
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
    .library(
      name: "UIKitNavigation",
      targets: ["UIKitNavigation"]
    ),
    .library(
      name: "AppKitNavigation",
      targets: ["AppKitNavigation"]
    ),
  ],
  traits: [
    .trait(
      name: "CasePaths",
      description: "Drive enum navigation and form data with CasePaths"
    ),
    .trait(
      name: "Sharing",
      description: "Derive bindings from '@Shared' state"
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", branch: "macro-support"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.2.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.2"),
    .package(url: "https://github.com/pointfreeco/swift-perception", "1.3.4"..<"3.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.8.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.4.1"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"605.0.0"),
  ],
  targets: [
    .macro(
      name: "SwiftNavigationMacros",
      dependencies: [
        .product(name: "CasePathsMacrosSupport", package: "swift-case-paths"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SwiftNavigation",
      dependencies: [
        .target(
          name: "SwiftNavigationMacros",
          condition: .when(traits: [
            "CasePaths"
          ])
        ),
        .product(
          name: "CasePaths",
          package: "swift-case-paths",
          condition: .when(traits: [
            "CasePaths"
          ])
        ),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
        .product(name: "OrderedCollections", package: "swift-collections"),
        .product(name: "Perception", package: "swift-perception"),
        .product(name: "PerceptionCore", package: "swift-perception"),
        .product(
          name: "Sharing",
          package: "swift-sharing",
          condition: .when(traits: [
            "Sharing"
          ])
        ),
      ]
    ),
    .testTarget(
      name: "SwiftNavigationTests",
      dependencies: [
        "SwiftNavigation",
        .product(name: "IssueReportingTestSupport", package: "xctest-dynamic-overlay"),
      ]
    ),
    .target(
      name: "SwiftUINavigation",
      dependencies: [
        "UIKitNavigation",
        .product(
          name: "CasePaths",
          package: "swift-case-paths",
          condition: .when(traits: [
            "CasePaths"
          ])
        ),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
      ]
    ),
    .testTarget(
      name: "SwiftUINavigationTests",
      dependencies: [
        "SwiftUINavigation",
        .product(name: "IssueReportingTestSupport", package: "xctest-dynamic-overlay"),
      ]
    ),
    .target(
      name: "UIKitNavigation",
      dependencies: [
        "SwiftNavigation",
        "UIKitNavigationShim",
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
      ]
    ),
    .target(
      name: "UIKitNavigationShim"
    ),
    .target(
      name: "AppKitNavigation",
      dependencies: [
        "SwiftNavigation"
      ]
    ),
    .testTarget(
      name: "UIKitNavigationTests",
      dependencies: [
        "UIKitNavigation",
        .product(name: "IssueReportingTestSupport", package: "xctest-dynamic-overlay"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)

let enableAllTraits =
  ProcessInfo.processInfo.environment["ENABLE_ALL_TRAITS"] != nil
  // NB: https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server/issues/2336
  || ProcessInfo.processInfo.environment["SPI_GENERATE_DOCS"] != nil

package.traits.insert(
  .default(
    enabledTraits: Set(enableAllTraits ? package.traits.map(\.name) : ["CasePaths"])
  )
)

for target in package.targets where target.name != "SwiftNavigationMacros" {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(contentsOf: [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  ])
}

if ProcessInfo.processInfo.environment["OMIT_MACRO_TESTS"] == nil {
  package.dependencies.append(
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0")
  )
  package.targets.append(
    .testTarget(
      name: "SwiftNavigationMacrosTests",
      dependencies: [
        "SwiftNavigationMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    )
  )
}
