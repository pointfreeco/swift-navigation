import UIKitNavigation
import XCTest

final class PresentationTests: XCTestCase {
  @MainActor
  func testPresents_IsPresented() async throws {
    let vc = BasicViewController()
    try await setUp(controller: vc)

    await assertEventuallyEqual(vc.presentedViewController, nil)

    vc.model.isPresented = true
    await assertEventuallyNotEqual(vc.presentedViewController, nil)

    vc.model.isPresented = false
    await assertEventuallyEqual(vc.presentedViewController, nil)
  }

  @MainActor
  func testPresents_Item() async throws {
    let vc = BasicViewController()
    try await setUp(controller: vc)

    await assertEventuallyEqual(vc.presentedViewController, nil)
    
    vc.model.presentedChild = Model()
    await assertEventuallyNotEqual(vc.presentedViewController, nil)
    
    vc.model.presentedChild = nil
    await assertEventuallyEqual(vc.presentedViewController, nil)
  }

  @MainActor
  func testPresents_TraitDismissal() async throws {
    let vc = BasicViewController()
    try await setUp(controller: vc)
    
    await assertEventuallyEqual(vc.presentedViewController, nil)

    vc.model.isPresented = true
    await assertEventuallyNotEqual(vc.presentedViewController, nil)

    vc.presentedViewController?.traitCollection.dismiss()
    await assertEventuallyEqual(vc.presentedViewController, nil)
    await assertEventuallyEqual(vc.model.isPresented, false)
  }

  @MainActor
  func testPresents_DeepLink() async throws {
    let vc = BasicViewController(model: Model(isPresented: true))
    try await setUp(controller: vc)

    await assertEventuallyNotEqual(vc.presentedViewController, nil)
    
    vc.model.isPresented = false
    await assertEventuallyEqual(vc.presentedViewController, nil)
  }

  @MainActor
  func testPresents_DeepLink_EarlyViewDidLoad() async throws {
    let vc = BasicViewController(model: Model(isPresented: true))
    _ = vc.view
    try await Task.sleep(for: .seconds(0.1))
    try await setUp(controller: vc)
    
    XCTTODO(
      """
      This does not currently pass because we eagerly present in `viewDidLoad` but really we should
      wait for `viewDidAppear`.
      """)

    await assertEventuallyNotEqual(vc.presentedViewController, nil)

    vc.model.isPresented = false
    await assertEventuallyEqual(vc.presentedViewController, nil)
  }

  @MainActor
  func testPushViewController_IsPushed() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)

    vc.model.isPushed = true
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    vc.model.isPushed = false
    await assertEventuallyEqual(nav.viewControllers.count, 1)
  }

  @MainActor
  func testPushViewController_Item() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)

    vc.model.pushedChild = Model()
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    vc.model.pushedChild = nil
    await assertEventuallyEqual(nav.viewControllers.count, 1)
  }

  @MainActor
  func testPushViewController_Pop_Represent() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)

    vc.model.pushedChild = Model()
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    
    nav.popViewController(animated: false)
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyNil(vc.model.pushedChild)

    await Task.yield()
    vc.model.pushedChild = Model()
    await assertEventuallyEqual(nav.viewControllers.count, 2)
  }

  @MainActor
  func testPushViewController_TraitDismissal() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)

    vc.model.isPushed = true
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    nav.viewControllers.last?.traitCollection.dismiss()
    await assertEventuallyEqual(nav.viewControllers.count, 1)
  }

  @MainActor
  func testPushViewController_DeepLink() async throws {
    let vc = BasicViewController(model: Model(isPushed: true))
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 2)
    
    vc.model.isPushed = false
    await assertEventuallyEqual(nav.viewControllers.count, 1)
  }

  @MainActor
  func testPushViewController_DeepLink_MultipleScreens() async throws {
    let vc = BasicViewController(
      model: Model(pushedChild: Model(pushedChild: Model(pushedChild: Model())))
    )
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 4)
  }

  @MainActor
  func testPushViewController_DeepLink_EarlyViewDidLoad() async throws {
    let vc = BasicViewController(model: Model(isPushed: true))
    _ = vc.view
    try await Task.sleep(for: .seconds(0.2))
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    XCTTODO(
      """
      This does not currently pass because we eagerly present in `viewDidLoad` but really we should
      wait for `viewDidAppear`.
      """)

    await assertEventuallyEqual(nav.viewControllers.count, 2)

    vc.model.isPushed = false
    await assertEventuallyEqual(nav.viewControllers.count, 1)
  }

  @MainActor
  func testPushViewController_DismissMultipleScreens() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)

    vc.model.pushedChild = Model()
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    vc.model.pushedChild?.pushedChild = Model()
    await assertEventuallyEqual(nav.viewControllers.count, 3)

    vc.model.pushedChild?.pushedChild?.pushedChild = Model()
    await assertEventuallyEqual(nav.viewControllers.count, 4)

    nav.viewControllers[1].traitCollection.dismiss()
    await assertEventuallyEqual(nav.viewControllers.count, 1)
  }

  @MainActor
  func testPushViewController_ManualPop() async throws {
    let vc = BasicViewController(
      model: Model(pushedChild: Model(pushedChild: Model(pushedChild: Model())))
    )
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 4)

    nav.popViewController(animated: false)
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    await assertEventuallyNil(vc.model.pushedChild?.pushedChild?.pushedChild)
    await assertEventuallyNotNil(vc.model.pushedChild?.pushedChild)

    nav.popViewController(animated: false)
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyNil(vc.model.pushedChild?.pushedChild)
    await assertEventuallyNotNil(vc.model.pushedChild)

    nav.popViewController(animated: false)
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyNotNil(vc.model.pushedChild)
  }

  @MainActor
  func testPresent_RepresentOnIdentityChange() async throws {
    let vc = BasicViewController()
    try await setUp(controller: vc)

    await assertEventuallyNil(vc.presentedViewController)
    
    vc.model.presentedChild = Model()
    await assertEventuallyNotNil(vc.presentedViewController)

    vc.model.presentedChild = Model()
    await assertEventuallyEqual(
      (vc.presentedViewController as? BasicViewController)?.model.id,
      vc.model.presentedChild?.id
    )
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
