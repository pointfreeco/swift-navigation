import UIKitNavigation
import XCTest

final class NavigationStackTests: XCTestCase {
  @MainActor
  func testMutatingBinding() async throws {
    @UIBindable var model = Model()
    let nav = NavigationStackController(path: $model.path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try setUp(controller: nav)

    model.path.append(1)
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(nav.visibleViewController?.isViewLoaded, true)
    XCTAssertEqual(model.path, [1])

    model.path.append(2)
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyEqual(nav.visibleViewController?.isViewLoaded, true)
    try await Task.sleep(for: .seconds(1))
    XCTAssertEqual(model.path, [1, 2])

    model.path.removeLast()
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    XCTAssertEqual(model.path, [1])

//    model.path.removeLast()
//    await assertEventually {
//      nav.viewControllers.count == 1
//    }
//    XCTAssertEqual(model.path, [])
  }

  @MainActor
  func testAppendSameData() async throws {
    @UIBindable var model = Model()
    let nav = NavigationStackController(path: $model.path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try setUp(controller: nav)

    model.path.append(1)
    await assertEventually {
      nav.viewControllers.count == 2 && nav.visibleViewController?.isViewLoaded == true
    }
    model.path.append(1)
    XCTTODO(
      """
      This doesn't pass because we pushed the same value onto the stack twice.
      """
    )
    await assertEventually {
      nav.viewControllers.count == 3 && nav.visibleViewController?.isViewLoaded == true
    }
  }

  @MainActor
  func testDeepLink() async throws {
    @UIBindable var model = Model(path: [1, 2, 3])
    let nav = NavigationStackController(path: $model.path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try setUp(controller: nav)

    await assertEventually {
      nav.viewControllers.count == 4
    }
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? ChildViewController)?.number },
      [1, 2, 3]
    )
  }

  @MainActor
  func testManualPopLast() async throws {
    @UIBindable var model = Model()
    let nav = NavigationStackController(path: $model.path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try setUp(controller: nav)

    model.path.append(1)
    await assertEventually {
      nav.viewControllers.count == 2
    }
    try await Task.sleep(for: .seconds(0.1))
    nav.popViewController(animated: false)
    await assertEventually {
      model.path == []
    }
    await assertEventually {
      nav.viewControllers.count == 1
    }
  }

  @MainActor
  func testManualPopMiddle() async throws {
    @UIBindable var model = Model(path: [1, 2, 3, 4])
    let nav = NavigationStackController(path: $model.path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try setUp(controller: nav)

    await assertEventually {
      nav.viewControllers.count == 5 && nav.visibleViewController?.isViewLoaded == true
    }
    nav.popToViewController(nav.viewControllers[2], animated: false)
    await assertEventually {
      model.path == [1, 2]
    }
    await assertEventually {
      nav.viewControllers.count == 3
    }
  }
}

@Observable
private class Model {
  var path: [Int]
  init(path: [Int] = []) {
    self.path = path
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
