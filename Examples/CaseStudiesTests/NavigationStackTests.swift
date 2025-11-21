import UIKitNavigation
import UIKitNavigationShim
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

  @MainActor
  func testAppendMultipleValuesAtOnce() async throws {
    @UIBinding var path = [Int]()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)

    path = [1, 2]
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? ChildViewController)?.number },
      [1, 2]
    )

    path = [1, 2, 3, 4]
    await assertEventuallyEqual(nav.viewControllers.count, 5)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? ChildViewController)?.number },
      [1, 2, 3, 4]
    )
  }

  @MainActor
  func testRemoveMultipleValuesAtOnce() async throws {
    @UIBinding var path = [1, 2, 3, 4, 5, 6]
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 7)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? ChildViewController)?.number },
      [1, 2, 3, 4, 5, 6]
    )

    path = [1, 2, 3, 4]
    await assertEventuallyEqual(nav.viewControllers.count, 5)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? ChildViewController)?.number },
      [1, 2, 3, 4]
    )

    path = [1, 2]
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? ChildViewController)?.number },
      [1, 2]
    )

    path = []
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? ChildViewController)?.number },
      []
    )
  }

  @MainActor
  func testReorderStack() async throws {
    @UIBinding var path = [1, 2, 3, 4]
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 5)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      path = [4, 1, 3, 2]
    }
    await assertEventuallyEqual(nav.viewControllers.count, 5)
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? ChildViewController)?.number },
      [4, 1, 3, 2]
    )
  }

  @MainActor
  func testPushLeafFeatureOutsideOfPath() async throws {
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

    var child = try XCTUnwrap(nav.viewControllers[1] as? ChildViewController)
    child.isLeafPresented = true
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(path, [1])

    child = try XCTUnwrap(nav.viewControllers[2] as? ChildViewController)
    child.isLeafPresented = true
    await assertEventuallyEqual(nav.viewControllers.count, 4)
    await assertEventuallyEqual(path, [1])

    nav.popViewController(animated: false)
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(path, [1])

    nav.popViewController(animated: false)
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(path, [1])
  }

  @MainActor
  func testLeafFeatureOutsideOfPath_AppendToPath() async throws {
    @UIBinding var path = [Int]()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try await setUp(controller: nav)
    await assertEventuallyEqual(nav._UIKitNavigation_hasViewAppeared, true)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      path.append(1)
    }
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(path, [1])

    let child = try XCTUnwrap(nav.viewControllers[1] as? ChildViewController)
    withUITransaction(\.uiKit.disablesAnimations, true) {
      child.isLeafPresented = true
    }
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(path, [1])

    try await Task.sleep(for: .seconds(0.1))
    withUITransaction(\.uiKit.disablesAnimations, true) {
      path.append(2)
    }
    await assertEventuallyEqual(nav.viewControllers.count, 4)
    await assertEventuallyEqual(path, [1, 2])
  }

  @MainActor
  func testPushAction() async throws {
    @UIBinding var path = [Int]()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try await setUp(controller: nav)

    try await Task.sleep(for: .seconds(0.3))
    nav.traitCollection.push(value: 1)
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(path, [1])

    try await Task.sleep(for: .seconds(0.3))
    nav.viewControllers[0].traitCollection.push(value: 2)
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(path, [1, 2])

    try await Task.sleep(for: .seconds(0.3))
    nav.viewControllers[1].traitCollection.push(value: 3)
    await assertEventuallyEqual(nav.viewControllers.count, 4)
    await assertEventuallyEqual(path, [1, 2, 3])

    try await Task.sleep(for: .seconds(0.3))
    try XCTUnwrap(nav.viewControllers.last).traitCollection.push(value: 4)
    await assertEventuallyEqual(nav.viewControllers.count, 5)
    await assertEventuallyEqual(path, [1, 2, 3, 4])
  }
}

private final class ChildViewController: UIViewController {
  let number: Int
  @UIBinding var isLeafPresented: Bool

  init(number: Int, isLeafPresented: Bool = false) {
    self.number = number
    self.isLeafPresented = isLeafPresented
    super.init(nibName: nil, bundle: nil)
    navigationItem.title = "\(number)"
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override var debugDescription: String {
    "ChildViewController.\(number)"
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationDestination(isPresented: $isLeafPresented) { [weak self] in
      ChildViewController(number: self?.number ?? 0)
    }
  }
}
