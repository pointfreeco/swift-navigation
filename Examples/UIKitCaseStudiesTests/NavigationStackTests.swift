import UIKitNavigation
import XCTest

final class NavigationStackTests: XCTestCase {
  @MainActor
  func testMutatingBinding() async throws {
    @UIBinding var path = [Int]()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try await setUp(controller: nav)

    path.append(1)
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(path, [1])

    path.append(2)
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(path, [1, 2])

    path.removeLast()
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(path, [1])

    path.removeLast()
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(path, [])
  }

  @MainActor
  func testAppendSameData() async throws {
    @UIBinding var path = [Int]()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try await setUp(controller: nav)

    path.append(1)
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    path.append(1)
    await assertEventuallyEqual(nav.viewControllers.count, 3)
  }

  @MainActor
  func testDeepLink() async throws {
    @UIBinding var path = [1, 2, 3]
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 4)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? ChildViewController)?.number },
      [1, 2, 3]
    )
  }

  @MainActor
  func testManualPopLast() async throws {
    @UIBinding var path = [Int]()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try await setUp(controller: nav)

    path.append(1)
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    nav.popViewController(animated: false)
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(path, [])
  }

  @MainActor
  func testManualPopMiddle() async throws {
    @UIBinding var path = [1, 2, 3, 4]
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 5)

    nav.popToViewController(nav.viewControllers[2], animated: false)
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(path, [1, 2])
  }
}

private final class ChildViewController: UIViewController {
  let number: Int
  init(number: Int) {
    self.number = number
    super.init(nibName: nil, bundle: nil)
    self.navigationItem.title = "\(number)"
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
