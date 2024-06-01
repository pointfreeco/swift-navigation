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
      NumberViewController(value: number)
    }
    try await setUp(controller: nav)

    path.append(1)
    await assertEventually {
      nav.viewControllers.count == 2
    }
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? NumberViewController)?.value },
      [1]
    )

    path.append(2)
    await assertEventually {
      nav.viewControllers.count == 3
    }
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? NumberViewController)?.value },
      [1, 2]
    )

    path.removeLast()
    await assertEventually {
      nav.viewControllers.count == 2
    }
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? NumberViewController)?.value },
      [1]
    )

    path.removeLast()
    await assertEventually {
      nav.viewControllers.count == 1
    }
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? NumberViewController)?.value },
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
      NumberViewController(value: number)
    }
    nav.navigationDestination(for: String.self) { string in
      StringViewController(value: string)
    }
    try await setUp(controller: nav)
    //try await Task.sleep(for: .seconds(0.1))

    path.append(1)
    await assertEventually {
      nav.viewControllers.count == 2
    }
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? NumberViewController)?.value },
      [1]
    )
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? StringViewController)?.value },
      []
    )

    path.append("blob")
    await assertEventuallyEqual(
      nav.viewControllers.count,
      3
    )
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? NumberViewController)?.value },
      [1]
    )
    await assertEventuallyEqual(
      nav.viewControllers.compactMap { ($0 as? StringViewController)?.value },
      ["blob"]
    )

    path.removeLast()
    await assertEventually {
      nav.viewControllers.count == 2
    }
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? NumberViewController)?.value },
      [1]
    )
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? StringViewController)?.value },
      []
    )
    
    path.removeLast()
    await assertEventually {
      nav.viewControllers.count == 1
    }
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? NumberViewController)?.value },
      []
    )
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? StringViewController)?.value },
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
      NumberViewController(value: number)
    }
    try await setUp(controller: nav)

    await assertEventually {
      nav.viewControllers.count == 4
    }
    XCTAssertEqual(
      nav.viewControllers.compactMap { ($0 as? NumberViewController)?.value },
      [1, 2, 3]
    )
  }
}

private final class NumberViewController: UIViewController {
  let value: Int
  init(value: Int) {
    self.value = value
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
}
