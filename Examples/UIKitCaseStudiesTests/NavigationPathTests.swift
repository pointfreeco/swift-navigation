@_spi(Internals) import SwiftNavigation
import UIKitNavigation
import XCTest

final class NavigationPathTests: XCTestCase {
  @MainActor
  func testMutateBinding() async throws {
    @UIBinding var path = UINavigationPath()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ValueViewController(value: number)
    }
    try await setUp(controller: nav)

    path.append(1)
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      [1]
    )

    path.append(2)
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      [1, 2]
    )

    path.removeLast()
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      [1, 2]
    )

    path.removeLast()
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      []
    )
  }

  @MainActor
  func testHeterogenuousPath() async throws {
    @UIBinding var path = UINavigationPath()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ValueViewController(value: number)
    }
    nav.navigationDestination(for: String.self) { string in
      ValueViewController(value: string)
    }
    try await setUp(controller: nav)

    path.append(1)
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      [1]
    )
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      []
    )

    path.append("blob")
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      [1]
    )
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      ["blob"]
    )

    path.removeLast()
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      [1]
    )
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      []
    )

    path.removeLast()
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      []
    )
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      []
    )
  }

  @MainActor
  func testDeepLink() async throws {
    @UIBinding var path = UINavigationPath([1, 2, 3])
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ValueViewController(value: number)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 4)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      [1, 2, 3]
    )
  }

  @MainActor
  func testDeepLink_UnrecognizedType() async throws {
    @UIBinding var path = UINavigationPath(["blob"])
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ValueViewController(value: number)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)
  }

  @MainActor
  func testDecodePath() async throws {
    @UIBinding var path = UINavigationPath(
      try JSONDecoder().decode(
        UINavigationPath.CodableRepresentation.self,
        from: Data(
          #"""
          ["Sb","true","SS","\"Blob\"","Si","1"]
          """#.utf8)
      )
    )
    await assertEventuallyEqual(
      path.elements,
      [
        .lazy(.init(tag: "Si", item: "1")),
        .lazy(.init(tag: "SS", item: "\"Blob\"")),
        .lazy(.init(tag: "Sb", item: "true")),
      ]
    )

    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { value in
      ValueViewController(value: value)
    }
    nav.navigationDestination(for: String.self) { value in
      ValueViewController(value: value)
    }
    nav.navigationDestination(for: Bool.self) { value in
      ValueViewController(value: value)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 4)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      [1, "Blob", true] as [AnyHashable]
    )
    await assertEventuallyEqual(
      path.elements,
      [.eager(1), .eager("Blob"), .eager(true)]
    )
  }

  @MainActor
  func testDecodePath_Laziness() async throws {
    @UIBinding var path = UINavigationPath(
      try JSONDecoder().decode(
        UINavigationPath.CodableRepresentation.self,
        from: Data(
          #"""
          ["Sb","true","SS","\"Blob\"","Si","1"]
          """#.utf8)
      )
    )
    await assertEventuallyEqual(
      path.elements,
      [
        .lazy(.init(tag: "Si", item: "1")),
        .lazy(.init(tag: "SS", item: "\"Blob\"")),
        .lazy(.init(tag: "Sb", item: "true")),
      ]
    )

    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { value in
      ValueViewController(value: value)
    }
    nav.navigationDestination(for: String.self) { value in
      ValueViewController(value: value)
    }
    nav.navigationDestination(for: Bool.self) { value in
      ValueViewController(value: value)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 4)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      [1, "Blob", true] as [AnyHashable]
    )
    await assertEventuallyEqual(
      path.elements,
      [.eager(1), .eager("Blob"), .eager(true)]
    )

    @MainActor
    func testDecodePath_Laziness() async throws {
      @UIBinding var path = UINavigationPath(
        try JSONDecoder().decode(
          UINavigationPath.CodableRepresentation.self,
          from: Data(
            #"""
            ["Sb","true","SS","\"Blob\"","Si","1"]
            """#.utf8)
        )
      )
      await assertEventuallyEqual(
        path.elements,
        [
          .lazy(.init(tag: "Si", item: "1")),
          .lazy(.init(tag: "SS", item: "\"Blob\"")),
          .lazy(.init(tag: "Sb", item: "true")),
        ]
      )

      let nav = NavigationStackController(path: $path) {
        UIViewController()
      }
      nav.navigationDestination(for: Int.self) { value in
        ValueViewController(value: value)
      }
      nav.navigationDestination(for: String.self) { value in
        ValueViewController(value: value)
      }
      nav.navigationDestination(for: Bool.self) { value in
        ValueViewController(value: value)
      }
      try await setUp(controller: nav)

      await assertEventuallyEqual(nav.viewControllers.count, 4)
      await assertEventuallyEqual(
        nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
        [1, "Blob", true] as [AnyHashable]
      )
      await assertEventuallyEqual(
        path.elements,
        [.eager(1), .eager("Blob"), .eager(true)]
      )
    }
  }

  @MainActor
  func testDecodePath_NestedNavigationDestination() async throws {
    @UIBinding var path = UINavigationPath(
      try JSONDecoder().decode(
        UINavigationPath.CodableRepresentation.self,
        from: Data(
          #"""
          ["Sb","true","SS","\"Blob\"","Si","1"]
          """#.utf8)
      )
    )
    await assertEventuallyEqual(
      path.elements,
      [
        .lazy(.init(tag: "Si", item: "1")),
        .lazy(.init(tag: "SS", item: "\"Blob\"")),
        .lazy(.init(tag: "Sb", item: "true")),
      ]
    )

    let nav = NavigationStackController(path: $path) {
      RootViewController()
    }

    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 4)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      [1, "Blob", true] as [AnyHashable]
    )
    await assertEventuallyEqual(
      path.elements,
      [.eager(1), .eager("Blob"), .eager(true)]
    )
  }

  @MainActor
  func testDecodePath_NestedNavigationDestination_UnrecognizedType() async throws {
    @UIBinding var path = UINavigationPath(
      try JSONDecoder().decode(
        UINavigationPath.CodableRepresentation.self,
        from: Data(
          #"""
          [
            "Sb","true",
            "SS","\"Blob\"",
            "\#(User.mangledTypeName)","{}",
            "Si","1"
          ]
          """#.utf8)
      )
    )
    await assertEventuallyEqual(
      path.elements,
      [
        .lazy(.init(tag: "Si", item: "1")),
        .lazy(.init(tag: "SS", item: "\"Blob\"")),
        .lazy(.init(tag: User.mangledTypeName, item: "{}")),
        .lazy(.init(tag: "Sb", item: "true")),
      ]
    )

    let nav = NavigationStackController(path: $path) {
      RootViewController()
    }

    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 4)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable },
      [1, "Blob", true] as [AnyHashable]
    )
    await assertEventuallyEqual(
      path.elements,
      [.eager(1), .eager("Blob"), .eager(true)]
    )
  }

  @MainActor
  func testDecodePath_UnrecognizedType() async throws {
    @UIBinding var path = UINavigationPath(
      try JSONDecoder().decode(
        UINavigationPath.CodableRepresentation.self,
        from: Data(
          #"""
          ["\#(User.mangledTypeName)","{}"]
          """#.utf8)
      )
    )
    await assertEventuallyEqual(
      path.elements,
      [
        .lazy(
          .init(
            tag: User.mangledTypeName,
            item: "{}"
          )
        )
      ]
    )

    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(path.elements, [])
  }
}

@MainActor
private protocol _ValueViewController: UIViewController {
  associatedtype Value
  var value: Value { get }
}
private final class ValueViewController<Value>: UIViewController, _ValueViewController {
  let value: Value
  init(value: Value) {
    self.value = value
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private final class RootViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationDestination(for: Int.self) { int in
      IntegerViewController(value: int)
    }
  }
}

private final class IntegerViewController: UIViewController {
  let value: Int
  init(value: Int) {
    self.value = value
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationDestination(for: String.self) { string in
      StringViewController(value: string)
    }
  }
}

private final class StringViewController: UIViewController {
  let value: String
  init(value: String) {
    self.value = value
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationDestination(for: Bool.self) { bool in
      BoolViewController(value: bool)
    }
  }
}

private final class BoolViewController: UIViewController {
  let value: Bool
  init(value: Bool) {
    self.value = value
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
  }
}

private struct User: Hashable, Codable {
  static let mangledTypeName =
    "21UIKitCaseStudiesTests014NavigationPathD0C10$10685e7e0yXZ10$10685e7ecyXZ4UserV"
}
