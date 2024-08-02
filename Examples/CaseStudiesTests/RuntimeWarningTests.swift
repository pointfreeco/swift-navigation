import UIKitNavigation
import XCTest

final class RuntimeWarningTests: XCTestCase {
  @MainActor
  func testDismissWhenNotPresented() async throws {
    XCTExpectFailure {
      let vc = UIViewController()
      vc.traitCollection.dismiss()
    } issueMatcher: {
      $0.compactDescription == """
        failed - A view controller requested dismissal, but couldn't be dismissed.

        'UITraitCollection.dismiss()' must be called from an object that was presented using a \
        binding, for example 'UIViewController.present(item:)', and \
        'UIViewController.navigationDestination(item:)'.
        """
    }
  }

  @MainActor
  func testNavigationDestination_WithoutNavigationController() async throws {
    XCTExpectFailure {
      $0.compactDescription == """
        failed - Can't present navigation item: "navigationController" is "nil".
        """
    }
    class VC: UIViewController {
      override func viewDidLoad() {
        navigationDestination(item: .constant(0 as Int?)) { _ in
          UIViewController()
        }
      }
    }
    let vc = VC()
    try await setUp(controller: vc)
  }

  @MainActor
  func testPushValue_WithoutNavigationStack() async throws {
    XCTExpectFailure {
      $0.compactDescription == """
        failed - Tried to push a value from outside of a navigation stack.

        'UITraitCollection.push(value:)' must be called from an object in a \
        'NavigationStackController'.
        """
    }
    class VC: UIViewController {
      override func viewDidLoad() {
        traitCollection.push(value: 1)
      }
    }
    let vc = VC()
    try await setUp(controller: vc)
  }

  @MainActor
  func testPushValue_WithoutNavigationController() async throws {
    XCTExpectFailure {
      $0.compactDescription == """
        failed - Tried to push a value from outside of a navigation stack.

        'UITraitCollection.push(value:)' must be called from an object in a \
        'NavigationStackController'.
        """
    }
    class VC: UIViewController {
      override func viewDidLoad() {
        traitCollection.push(value: 1)
      }
    }
    let vc = UINavigationController(rootViewController: VC())
    try await setUp(controller: vc)
  }

  @MainActor
  func testPush_WithoutNavigationController() async throws {
    XCTExpectFailure {
      $0.compactDescription == """
        failed - Can't push value: "navigationController" is "nil".
        """
    }
    class VC: UIViewController {
      override func viewDidLoad() {
        push(value: 1)
      }
    }
    let vc = VC()
    try await setUp(controller: vc)
  }

  @MainActor
  func testPush_WithoutNavigationStack() async throws {
    XCTExpectFailure {
      $0.compactDescription == """
        failed - Tried to push a value to a non-"NavigationStackController".
        """
    }
    class VC: UIViewController {
      override func viewDidLoad() {
        push(value: 1)
      }
    }
    let vc = UINavigationController(rootViewController: VC())
    try await setUp(controller: vc)
  }

  @MainActor
  func testNavigationDestinationFor_WithoutNavigationController() async throws {
    XCTExpectFailure {
      $0.compactDescription == """
        failed - Can't register navigation destination: "navigationController" is "nil".
        """
    }
    class VC: UIViewController {
      override func viewDidLoad() {
        navigationDestination(for: Int.self) { _ in
          UIViewController()
        }
      }
    }
    let vc = VC()
    try await setUp(controller: vc)
  }

  @MainActor
  func testNavigationDestinationFor_WithoutNavigationStackController() async throws {
    XCTExpectFailure {
      $0.compactDescription == """
        failed - Tried to apply a "navigationDestination" to a non-"NavigationStackController".
        """
    }
    class VC: UIViewController {
      override func viewDidLoad() {
        navigationDestination(for: Int.self) { _ in
          UIViewController()
        }
      }
    }
    let vc = UINavigationController(rootViewController: VC())
    try await setUp(controller: vc)
  }
}
