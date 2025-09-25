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
    await assertEventuallyEqual(nav.values, [1])

    path.append(2)
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(nav.values, [1, 2])

    path.removeLast()
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(nav.values, [1])

    path.removeLast()
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(nav.values, [])
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
    await assertEventuallyEqual(nav.values, [1])

    path.append("blob")
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(nav.values, [1, "blob"])

    path.removeLast()
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(nav.values, [1])

    path.removeLast()
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(nav.values, [])
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
    await assertEventuallyEqual(nav.values, [1, 2, 3])
  }

  @MainActor
  func testPushAndPopStaticPath() async throws {
    @UIBinding var path: [Int] = []

    let nav = NavigationStackController(path: $path) {
      let controller = UIViewController()
      controller.view.backgroundColor = .init(
        red: .random(in: 0...1),
        green: .random(in: 0...1),
        blue: .random(in: 0...1),
        alpha: 1
      )
      return controller
    }
    nav.navigationDestination(for: Int.self) { number in
      ValueViewController(value: number)
    }
    try await setUp(controller: nav)

    path.append(1)
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(nav.values, [1])
    await assertEventuallyEqual(path, [1])

    nav.popViewController(animated: true)
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(nav.values, [])
    await assertEventuallyEqual(path, [])

    path.append(1)
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(nav.values, [1])
    await assertEventuallyEqual(path, [1])

    nav.popViewController(animated: true)
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(nav.values, [])
    await assertEventuallyEqual(path, [])
  }

  @MainActor
  func testPushAndPopTypeErasedPath() async throws {
    @UIBinding var path = UINavigationPath()

    let nav = NavigationStackController(path: $path) {
      let controller = UIViewController()
      controller.view.backgroundColor = .init(
        red: .random(in: 0...1),
        green: .random(in: 0...1),
        blue: .random(in: 0...1),
        alpha: 1
      )
      return controller
    }
    nav.navigationDestination(for: Int.self) { number in
      ValueViewController(value: number)
    }
    try await setUp(controller: nav)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      path.append(1)
    }
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(nav.values, [1])
    await assertEventuallyEqual(path.elements, [.lazy(.element(1))])

    try await Task.sleep(for: .seconds(0.1))

    _ = withUITransaction(\.uiKit.disablesAnimations, true) {
      nav.popViewController(animated: true)
    }
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(nav.values, [])
    await assertEventuallyEqual(path.elements, [])

    try await Task.sleep(for: .seconds(0.1))

    withUITransaction(\.uiKit.disablesAnimations, true) {
      path.append(1)
    }
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(nav.values, [1])
    await assertEventuallyEqual(path.elements, [.lazy(.element(1))])

    try await Task.sleep(for: .seconds(0.1))

    _ = withUITransaction(\.uiKit.disablesAnimations, true) {
      nav.popViewController(animated: true)
    }
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(nav.values, [])
    await assertEventuallyEqual(path.elements, [])
  }

  @MainActor
  func testDeepLink_UnrecognizedType() async throws {
    @UIBinding var path = UINavigationPath(["blob"])
    XCTExpectFailure {
      $0.compactDescription.hasPrefix(
        """
        failed - No "navigationDestination(for: String.self) { … }" was found among the view \
        controllers on the path.
        """
      )
    }
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ValueViewController(value: number)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(path.elements, [])
  }

  @MainActor
  func testAppend_UnrecognizedType() async throws {
    @UIBinding var path = UINavigationPath()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ValueViewController(value: number)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(path.elements, [])

    XCTExpectFailure {
      $0.compactDescription.hasPrefix(
        """
        failed - No "navigationDestination(for: String.self) { … }" was found among the view \
        controllers on the path.
        """
      )
    }
    path.append("blob")
    await assertEventuallyEqual(path.elements, [])
  }

  @MainActor
  func testPush_UnrecognizedType() async throws {
    @UIBinding var path = UINavigationPath()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ValueViewController(value: number)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(path.elements, [])

    XCTExpectFailure {
      $0.compactDescription.hasPrefix(
        """
        failed - No "navigationDestination(for: String.self) { … }" was found among the view \
        controllers on the path.
        """
      )
    }
    nav.traitCollection.push(value: "blob")
    await assertEventuallyEqual(path.elements, [])
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
        .lazy(.codable(.init(tag: "Si", item: "1"))),
        .lazy(.codable(.init(tag: "SS", item: "\"Blob\""))),
        .lazy(.codable(.init(tag: "Sb", item: "true"))),
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
    await assertEventuallyEqual(nav.values, [1, "Blob", true] as [AnyHashable])
    await assertEventuallyEqual(path.elements, [.eager(1), .eager("Blob"), .eager(true)])
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
        .lazy(.codable(.init(tag: "Si", item: "1"))),
        .lazy(.codable(.init(tag: "SS", item: "\"Blob\""))),
        .lazy(.codable(.init(tag: "Sb", item: "true"))),
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
    await assertEventuallyEqual(nav.values, [1, "Blob", true] as [AnyHashable])
    await assertEventuallyEqual(path.elements, [.eager(1), .eager("Blob"), .eager(true)])
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
    await assertEventuallyNoDifference(
      path.elements,
      [
        .lazy(.codable(.init(tag: "Si", item: "1"))),
        .lazy(.codable(.init(tag: "SS", item: "\"Blob\""))),
        .lazy(.codable(.init(tag: "Sb", item: "true"))),
      ]
    )

    let nav = NavigationStackController(path: $path) {
      LazyRootViewController()
    }

    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 4, timeout: 2)
    await assertEventuallyNoDifference(nav.values, [1, "Blob", true] as [AnyHashable])
    await assertEventuallyNoDifference(path.elements, [.eager(1), .eager("Blob"), .eager(true)])
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
    await assertEventuallyNoDifference(
      path.elements,
      [
        .lazy(.codable(.init(tag: "Si", item: "1"))),
        .lazy(.codable(.init(tag: User.mangledTypeName, item: "{}"))),
        .lazy(.codable(.init(tag: "SS", item: "\"Blob\""))),
        .lazy(.codable(.init(tag: "Sb", item: "true"))),
      ]
    )

    XCTExpectFailure {
      $0.compactDescription == """
        failed - Failed to decode item in navigation path at index 1. Perhaps the \
        "navigationDestination" declarations have changed since the path was encoded?
        """
    }
    let nav = NavigationStackController(path: $path) {
      LazyRootViewController()
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyNoDifference(nav.values, [1] as [AnyHashable])
    await assertEventuallyNoDifference(path.elements, [.eager(1)])
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
          .codable(
            .init(
              tag: User.mangledTypeName,
              item: "{}"
            )
          )
        )
      ]
    )

    XCTExpectFailure {
      $0.compactDescription == """
        failed - Failed to decode item in navigation path at index 0. Perhaps the \
        "navigationDestination" declarations have changed since the path was encoded?
        """
    }
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(path.elements, [])
  }

  @MainActor
  func testPushMultipleFeaturesAtOnce_LazyNavigationDestination() async throws {
    @UIBinding var path = UINavigationPath()

    let nav = NavigationStackController(path: $path) {
      LazyRootViewController()
    }

    try await setUp(controller: nav)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      path.append(2)
      path.append("Hello")
      path.append(true)
    }

    await assertEventuallyEqual(nav.viewControllers.count, 4, timeout: 2)
    await assertEventuallyNoDifference(
      nav.values,
      [2, "Hello", true] as [AnyHashable]
    )
    await assertEventuallyNoDifference(
      path.elements,
      [.eager(2), .eager("Hello"), .eager(true)]
    )
  }

  @MainActor
  func testPushMultipleFeaturesAtOnce_EagerNavigationDestination() async throws {
    @UIBinding var path = UINavigationPath()

    let nav = NavigationStackController(path: $path) {
      EagerRootViewController()
    }

    try await setUp(controller: nav)

    path.append(1)
    path.append("Hello")
    path.append(true)

    await assertEventuallyEqual(nav.viewControllers.count, 4)
    await assertEventuallyNoDifference(nav.titles, ["1", "Hello", "true"])
    await assertEventuallyNoDifference(path.elements, [.eager(1), .eager("Hello"), .eager(true)])
  }

  @MainActor
  func testRegisterNavigationDestinationTypeMultipleTimes_LastOneWins() async throws {
    @UIBinding var path = UINavigationPath()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { int in
      let vc = UIViewController()
      vc.title = "First: \(int)"
      return vc
    }
    nav.navigationDestination(for: Int.self) { int in
      let vc = UIViewController()
      vc.title = "Second: \(int)"
      return vc
    }

    try await setUp(controller: nav)

    path.append(1)
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyNoDifference(nav.titles, ["Second: 1"])
    await assertEventuallyNoDifference(path.elements, [.eager(1)])
    path.append(2)
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyNoDifference(nav.titles, ["Second: 1", "Second: 2"])
    await assertEventuallyNoDifference(path.elements, [.eager(1), .eager(2)])
  }
}

@MainActor
private protocol _ValueViewController: UIViewController {
  associatedtype Value: Hashable
  var value: Value { get }
}
private final class ValueViewController<Value: Hashable>: UIViewController, _ValueViewController {
  let value: Value
  init(value: Value) {
    self.value = value
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .init(
      red: .random(in: 0...1),
      green: .random(in: 0...1),
      blue: .random(in: 0...1),
      alpha: 1
    )
  }
}

extension UINavigationController {
  var values: [AnyHashable] {
    viewControllers.compactMap { ($0 as? any _ValueViewController)?.value as? AnyHashable }
  }
  var titles: [String] {
    viewControllers.compactMap(\.title)
  }
}

private final class LazyRootViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationDestination(for: Int.self) { int in
      IntegerViewController(value: int)
    }
  }
}

private final class EagerRootViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationDestination(for: Int.self) { int in
      let vc = UIViewController()
      vc.title = int.description
      return vc
    }
    navigationDestination(for: String.self) { string in
      let vc = UIViewController()
      vc.title = string
      return vc
    }
    navigationDestination(for: Bool.self) { bool in
      let vc = UIViewController()
      vc.title = "\(bool)"
      return vc
    }
  }
}

private final class IntegerViewController: UIViewController, _ValueViewController {
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
    navigationDestination(for: String.self) { string in
      StringViewController(value: string)
    }
  }
}

private final class StringViewController: UIViewController, _ValueViewController {
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
    navigationDestination(for: Bool.self) { bool in
      BoolViewController(value: bool)
    }
  }
}

private final class BoolViewController: UIViewController, _ValueViewController {
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

private final class UserViewController: UIViewController, _ValueViewController {
  let value: User
  init(value: User) {
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
  let id: Int
  static let mangledTypeName =
    "21UIKitCaseStudiesTests014NavigationPathD0C10$10685e7e0yXZ10$10685e7ecyXZ4UserV"
}
