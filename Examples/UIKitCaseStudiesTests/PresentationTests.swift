import UIKitNavigation
import XCTest

final class PresentationTests: XCTestCase {
  @MainActor
  func testPresents_IsPresented() async throws {
    let vc = BasicViewController()
    try setUp(controller: vc)
    XCTAssertEqual(vc.presentedViewController, nil)
    vc.model.isPresented = true
    await assertEventually {
      vc.presentedViewController != nil
    }
    vc.model.isPresented = false
    await assertEventually {
      vc.presentedViewController == nil
    }
  }

  @MainActor
  func testPresents_Item() async throws {
    let vc = BasicViewController()
    try setUp(controller: vc)
    XCTAssertEqual(vc.presentedViewController, nil)
    vc.model.presentedChild = Model()
    await assertEventually {
      vc.presentedViewController != nil
    }
    vc.model.presentedChild = nil
    await assertEventually {
      vc.presentedViewController == nil
    }
  }

  @MainActor
  func testPresents_TraitDismissal() async throws {
    let vc = BasicViewController()
    try setUp(controller: vc)
    XCTAssertEqual(vc.presentedViewController, nil)
    vc.model.isPresented = true
    await assertEventually {
      vc.presentedViewController != nil
    }
    vc.presentedViewController?.traitCollection.dismiss()
    await assertEventually {
      vc.presentedViewController == nil
    }
    XCTAssertEqual(vc.model.isPresented, false)
  }

  @MainActor
  func testPresents_DeepLink() async throws {
    let vc = BasicViewController(model: Model(isPresented: true))
    try setUp(controller: vc)
    await assertEventually {
      vc.presentedViewController != nil
    }
    vc.model.isPresented = false
    await assertEventually {
      vc.presentedViewController == nil
    }
  }

  @MainActor
  func testPresents_DeepLink_EarlyViewDidLoad() async throws {
    let vc = BasicViewController(model: Model(isPresented: true))
    _ = vc.view
    try await Task.sleep(for: .seconds(0.1))
    try setUp(controller: vc)
    XCTTODO(
      """
      This does not currently pass because we eagerly present in `viewDidLoad` but really we should
      wait for `viewDidAppear`.
      """)
    await assertEventually {
      vc.presentedViewController != nil
    }
    vc.model.isPresented = false
    await assertEventually {
      vc.presentedViewController == nil
    }
  }

  @MainActor
  func testPushViewController_IsPushed() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try setUp(controller: nav)
    XCTAssertEqual(nav.viewControllers.count, 1)
    vc.model.isPushed = true
    await assertEventually {
      nav.viewControllers.count == 2
    }
    vc.model.isPushed = false
    await assertEventually {
      nav.viewControllers.count == 1
    }
  }

  @MainActor
  func testPushViewController_Item() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try setUp(controller: nav)
    XCTAssertEqual(nav.viewControllers.count, 1)
    vc.model.pushedChild = Model()
    await assertEventually {
      nav.viewControllers.count == 2
    }
    vc.model.pushedChild = nil
    await assertEventually {
      nav.viewControllers.count == 1
    }
  }

  @MainActor
  func testPushViewController_Pop_Represent() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try setUp(controller: nav)
    XCTAssertEqual(nav.viewControllers.count, 1)
    vc.model.pushedChild = Model()
    await assertEventually {
      nav.viewControllers.count == 2
    }
    nav.popViewController(animated: false)
    await assertEventually {
      nav.viewControllers.count == 1
    }
    await assertEventually {
      vc.model.pushedChild == nil
    }
    await Task.yield()
    vc.model.pushedChild = Model()
    await assertEventually {
      nav.viewControllers.count == 2
    }
  }

  @MainActor
  func testPushViewController_TraitDismissal() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try setUp(controller: nav)
    XCTAssertEqual(nav.viewControllers.count, 1)
    vc.model.isPushed = true
    await assertEventually {
      nav.viewControllers.count == 2
    }
    nav.viewControllers.last?.traitCollection.dismiss()
    await assertEventually {
      nav.viewControllers.count == 1
    }
  }

  @MainActor
  func testPushViewController_DeepLink() async throws {
    let vc = BasicViewController(model: Model(isPushed: true))
    let nav = UINavigationController(rootViewController: vc)
    try setUp(controller: nav)
    await assertEventually {
      nav.viewControllers.count == 2
    }
    vc.model.isPushed = false
    await assertEventually {
      nav.viewControllers.count == 1
    }
  }

  @MainActor
  func testPushViewController_DeepLink_MultipleScreens() async throws {
    let vc = BasicViewController(
      model: Model(pushedChild: Model(pushedChild: Model(pushedChild: Model())))
    )
    let nav = UINavigationController(rootViewController: vc)
    try setUp(controller: nav)
    await assertEventually {
      nav.viewControllers.count == 4
    }
  }

  @MainActor
  func testPushViewController_DeepLink_EarlyViewDidLoad() async throws {
    let vc = BasicViewController(model: Model(isPushed: true))
    _ = vc.view
    try await Task.sleep(for: .seconds(0.2))
    let nav = UINavigationController(rootViewController: vc)
    try setUp(controller: nav)
    XCTTODO(
      """
      This does not currently pass because we eagerly present in `viewDidLoad` but really we should
      wait for `viewDidAppear`.
      """)
    await assertEventually {
      nav.viewControllers.count == 2
    }
    vc.model.isPushed = false
    await assertEventually {
      nav.viewControllers.count == 1
    }
  }

  @MainActor
  func testPushViewController_DismissMultipleScreens() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try setUp(controller: nav)
    XCTAssertEqual(nav.viewControllers.count, 1)
    vc.model.pushedChild = Model()
    await assertEventually {
      nav.viewControllers.count == 2
    }
    vc.model.pushedChild?.pushedChild = Model()
    await assertEventually {
      nav.viewControllers.count == 3
    }
    vc.model.pushedChild?.pushedChild?.pushedChild = Model()
    await assertEventually {
      nav.viewControllers.count == 4
    }
    nav.viewControllers[1].traitCollection.dismiss()
    await assertEventually {
      nav.viewControllers.count == 1
    }
  }

  @MainActor
  func testPushViewController_ManualPop() async throws {
    let vc = BasicViewController(
      model: Model(pushedChild: Model(pushedChild: Model(pushedChild: Model())))
    )
    let nav = UINavigationController(rootViewController: vc)
    try setUp(controller: nav)
    await assertEventually {
      nav.viewControllers.count == 4
    }
    nav.popViewController(animated: false)
    await assertEventually {
      nav.viewControllers.count == 3
    }
    await Task.yield()
    XCTAssertNil(vc.model.pushedChild?.pushedChild?.pushedChild)
    XCTAssertNotNil(vc.model.pushedChild?.pushedChild)
    nav.popViewController(animated: false)
    await assertEventually {
      nav.viewControllers.count == 2
    }
    await Task.yield()
    XCTAssertNil(vc.model.pushedChild?.pushedChild)
    XCTAssertNotNil(vc.model.pushedChild)
    nav.popViewController(animated: false)
    await assertEventually {
      nav.viewControllers.count == 1
    }
    await Task.yield()
    XCTAssertNil(vc.model.pushedChild)
  }

  @MainActor
  func testPresent_RepresentOnIdentityChange() async throws {
    let vc = BasicViewController()
    try setUp(controller: vc)
    XCTAssertEqual(vc.presentedViewController, nil)
    vc.model.presentedChild = Model()
    await assertEventually {
      vc.presentedViewController != nil
    }
    vc.model.presentedChild = Model()
    await assertEventually {
      (vc.presentedViewController as? BasicViewController)?.model.id
        == vc.model.presentedChild?.id
    }
  }
}

@Observable
private final class Model: Identifiable {
  var isPresented: Bool
  var isPushed: Bool
  var presentedChild: Model?
  var pushedChild: Model?
  var text: String
  init(
    isPresented: Bool = false,
    isPushed: Bool = false,
    presentedChild: Model? = nil,
    pushedChild: Model? = nil,
    text: String = ""
  ) {
    self.isPresented = isPresented
    self.isPushed = isPushed
    self.presentedChild = presentedChild
    self.pushedChild = pushedChild
    self.text = text
  }
}

private class BasicViewController: UIViewController {
  @UIBindable var model: Model
  init(model: Model = Model()) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    present(isPresented: $model.isPresented) {
      UIViewController()
    }
    present(item: $model.presentedChild) { model in
      BasicViewController(model: model)
    }
    navigationController?.pushViewController(isPresented: $model.isPushed) {
      UIViewController()
    }
    navigationController?.pushViewController(item: $model.pushedChild) { model in
      BasicViewController(model: model)
    }
  }
}
