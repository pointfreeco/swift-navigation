import XCTest
import UIKitNavigation

final class NavigationStackTests: XCTestCase {
  @MainActor
  func testBasics() async throws {
    @UIBindable var model = Model()
    let nav = UINavigationStackController(path: $model.path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { _ in
      UIViewController()
    }
    try setUp(controller: nav)

    model.path.append(1)
    await assertEventually {
      nav.viewControllers.count == 2
    }
    model.path.append(2)
    await assertEventually {
      nav.viewControllers.count == 3
    }
    model.path.removeLast()
    await assertEventually {
      nav.viewControllers.count == 2
    }
    model.path.removeLast()
    await assertEventually {
      nav.viewControllers.count == 1
    }
  }
  
  @MainActor
  func testAppendSameData() async throws {
    @UIBindable var model = Model()
    let nav = UINavigationStackController(path: $model.path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { _ in
      UIViewController()
    }
    try setUp(controller: nav)

    model.path.append(1)
    await assertEventually {
      nav.viewControllers.count == 2
    }
    model.path.append(1)
    XCTTODO("""
      This doesn't pass because we pushed the same value onto the stack twice.
      """)
    await assertEventually {
      nav.viewControllers.count == 3
    }
  }
}

@Observable
fileprivate class Model {
  var path: [Int]
  init(path: [Int] = []) {
    self.path = path
  }
}
