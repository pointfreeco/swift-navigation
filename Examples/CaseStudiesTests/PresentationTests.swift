import UIKitNavigation
import XCTest

final class PresentationTests: XCTestCase {
  @MainActor
  func testPresents_IsPresented() async throws {
    let vc = BasicViewController()
    try await setUp(controller: vc)

    await assertEventuallyNil(vc.presentedViewController)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.isPresented = true
    }
    await assertEventuallyNotNil(vc.presentedViewController)
    await assertEventuallyEqual(vc.isPresenting, true)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.isPresented = false
    }
    await assertEventuallyNil(vc.presentedViewController)
    await assertEventuallyEqual(vc.isPresenting, false)
  }

  @MainActor
  func testPresents_Item() async throws {
    let vc = BasicViewController()
    try await setUp(controller: vc)

    await assertEventuallyNil(vc.presentedViewController)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.presentedChild = Model()
    }
    await assertEventuallyNotNil(vc.presentedViewController)
    await assertEventuallyEqual(vc.isPresenting, true)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.presentedChild = nil
    }
    await assertEventuallyNil(vc.presentedViewController)
    await assertEventuallyEqual(vc.isPresenting, false)
  }

  @MainActor
  func testPresents_TraitDismissal() async throws {
    let vc = BasicViewController()
    try await setUp(controller: vc)

    await assertEventuallyNil(vc.presentedViewController)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.isPresented = true
    }
    await assertEventuallyNotNil(vc.presentedViewController)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.presentedViewController?.traitCollection.dismiss()
    }
    await assertEventuallyNil(vc.presentedViewController)
    await assertEventuallyEqual(vc.model.isPresented, false)
  }

  @MainActor
  func testPresents_DeepLink() async throws {
    let vc = BasicViewController(model: Model(isPresented: true))
    try await setUp(controller: vc)

    await assertEventuallyNotNil(vc.presentedViewController)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.isPresented = false
    }
    await assertEventuallyNil(vc.presentedViewController)
  }

  @MainActor
  func testPresents_DeepLink_EarlyViewDidLoad() async throws {
    let vc = BasicViewController(model: Model(isPresented: true))
    try await setUp(controller: vc)

    await assertEventuallyNotNil(vc.presentedViewController)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.isPresented = false
    }
    await assertEventuallyNil(vc.presentedViewController)
  }

  @MainActor
  func testPresents_Nested_ParentItemChanges() async throws {
    let vc = BasicViewController(model: Model(presentedChild: Model()))
    try await setUp(controller: vc)

    await assertEventuallyNotNil(vc.presentedViewController)

    let firstPresented = try XCTUnwrap(vc.presentedViewController)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.presentedChild?.presentedChild = Model()
    }
    await assertEventuallyNotNil(vc.presentedViewController?.presentedViewController)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.presentedChild = Model()
    }
    await assertEventuallyNotEqual(firstPresented, vc.presentedViewController)
  }

  @MainActor
  func testPushViewController_IsPushed() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.isPushed = true
    }
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.isPushed = false
    }
    await assertEventuallyEqual(nav.viewControllers.count, 1)
  }

  @MainActor
  func testPushViewController_Item() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.pushedChild = Model()
    }
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.pushedChild = nil
    }
    await assertEventuallyEqual(nav.viewControllers.count, 1)
  }

  @MainActor
  func testPushViewController_Pop_Represent() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.pushedChild = Model()
    }
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    try await Task.sleep(for: .seconds(1))
    nav.popViewController(animated: false)
    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyNil(vc.model.pushedChild)

    try await Task.sleep(for: .seconds(1))
    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.pushedChild = Model()
    }
    await assertEventuallyEqual(nav.viewControllers.count, 2)
  }

  @MainActor
  func testPushViewController_TraitDismissal() async throws {
    let vc = BasicViewController()
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

    await assertEventuallyEqual(nav.viewControllers.count, 1)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.isPushed = true
    }
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      nav.viewControllers.last?.traitCollection.dismiss()
    }
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
    let nav = UINavigationController(rootViewController: vc)
    try await setUp(controller: nav)

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

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.pushedChild = Model()
    }
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.pushedChild?.pushedChild = Model()
    }
    await assertEventuallyEqual(nav.viewControllers.count, 3)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.pushedChild?.pushedChild?.pushedChild = Model()
    }
    await assertEventuallyEqual(nav.viewControllers.count, 4)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      nav.viewControllers[1].traitCollection.dismiss()
    }
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

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.presentedChild = Model()
    }
    await assertEventuallyNotNil(vc.presentedViewController)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      vc.model.presentedChild = Model()
    }
    await assertEventuallyEqual(
      (vc.presentedViewController as? BasicViewController)?.model.id,
      vc.model.presentedChild?.id
    )
  }

  @MainActor
  func testPushFireAndForget_PushStateDriven() async throws {
    let nav = UINavigationController(rootViewController: ViewController())
    try await setUp(controller: nav)
    await assertEventuallyEqual(nav.viewControllers.count, 1)

    let child = BasicViewController(model: Model())
    nav.pushViewController(child, animated: false)
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    withUITransaction(\.uiKit.disablesAnimations, true) {
      child.model.isPushed = true
    }
    await assertEventuallyEqual(nav.viewControllers.count, 3)
    withUITransaction(\.uiKit.disablesAnimations, true) {
      nav.viewControllers[2].traitCollection.dismiss()
    }
    await assertEventuallyEqual(nav.viewControllers.count, 2)
  }

  @MainActor
  func testDismissMultiplePresentations() async throws {
    class VC: ViewController {
      @UIBinding var isPresented = false
      override func viewDidLoad() {
        super.viewDidLoad()
        present(isPresented: $isPresented) { VC() }
      }
    }

    let vc = VC()
    try await setUp(controller: vc)

    vc.isPresented = true
    await assertEventuallyNotNil(vc.presentedViewController)

    try XCTUnwrap(vc.presentedViewController as? VC).isPresented = true
    await assertEventuallyNotNil(vc.presentedViewController?.presentedViewController)

    vc.isPresented = false
    await assertEventuallyNil(vc.presentedViewController, timeout: 2)
  }

  @MainActor
  func testDismissLeafPresentationDirectly() async throws {
    class VC: ViewController {
      @UIBinding var isPresented = false
      override func viewDidLoad() {
        super.viewDidLoad()
        present(isPresented: $isPresented) { VC() }
      }
    }

    let vc = VC()
    try await setUp(controller: vc)

    vc.isPresented = true
    await assertEventuallyNotNil(vc.presentedViewController)

    try XCTUnwrap(vc.presentedViewController as? VC).isPresented = true
    await assertEventuallyNotNil(vc.presentedViewController?.presentedViewController)

    vc.presentedViewController?.presentedViewController?.dismiss(animated: false)
    try await Task.sleep(for: .seconds(0.5))
    await assertEventuallyNotNil(vc.presentedViewController, timeout: 2)
  }

  @MainActor func testDismissMiddlePresentation() async throws {
    class VC: ViewController {
      @UIBinding var isPresented = false
      override func viewDidLoad() {
        super.viewDidLoad()
        present(isPresented: $isPresented) { VC() }
      }
    }

    let vc = VC()
    try await setUp(controller: vc)

    vc.isPresented = true
    try await Task.sleep(for: .seconds(0.5))
    await assertEventuallyNotNil(vc.presentedViewController)

    try XCTUnwrap(vc.presentedViewController as? VC).isPresented = true
    try await Task.sleep(for: .seconds(0.5))
    await assertEventuallyNotNil(vc.presentedViewController?.presentedViewController)

    try XCTUnwrap(vc.presentedViewController?.presentedViewController as? VC).isPresented = true
    try await Task.sleep(for: .seconds(0.5))
    await assertEventuallyNotNil(vc.presentedViewController?.presentedViewController)

    try XCTUnwrap(vc.presentedViewController as? VC).isPresented = false
    try await Task.sleep(for: .seconds(0.5))
    await assertEventuallyNotNil(vc.presentedViewController as? VC)
    await assertEventuallyNil(vc.presentedViewController?.presentedViewController, timeout: 2)
  }

  @MainActor func testNestedPresentationParentDismissalDismissesChild() async throws {
    let nav = UINavigationController(rootViewController: ViewController())
    try await setUp(controller: nav)
    await assertEventuallyEqual(nav.viewControllers.count, 1)

    var child: BasicViewController? = BasicViewController(model: Model())
    nav.pushViewController(child!, animated: false)
    await assertEventuallyEqual(nav.viewControllers.count, 2)

    try await Task.sleep(for: .seconds(0.5))
    withUITransaction(\.uiKit.disablesAnimations, true) {
      child!.model.isPresented = true
    }
    try await Task.sleep(for: .seconds(0.5))

    await assertEventuallyNotNil(child!.presentedViewController)
    XCTAssertEqual(child!.presentedViewController, nav.presentedViewController)
    nav.popToRootViewController(animated: false)
    try await Task.sleep(for: .seconds(0.5))

    child = nil
    try await Task.sleep(for: .seconds(0.5))

    await assertEventuallyEqual(nav.viewControllers.count, 1)
    await assertEventuallyNil(nav.presentedViewController)
  }

  @MainActor func testAnimatedPopFromModallyNavigationController() async throws {
    class VC: ViewController {
      @UIBinding var presentedChild: Model?
      override func viewDidLoad() {
        super.viewDidLoad()
        present(item: $presentedChild) { model in
          let root = BasicViewController(model: model)
          return UINavigationController(rootViewController: root)
        }
      }
    }
    let vc = VC()
    try await setUp(controller: vc)

    vc.presentedChild = Model()
    await assertEventuallyNotNil(vc.presentedViewController)

    vc.presentedChild?.isPushed = true
    await assertEventuallyEqual(
      (vc.presentedViewController as? UINavigationController)?.viewControllers.count,
      2
    )

    try await Task.sleep(for: .seconds(0.3))
    vc.presentedChild?.isPushed = false
    await assertEventuallyEqual(
      (vc.presentedViewController as? UINavigationController)?.viewControllers.count,
      1
    )
    await assertEventuallyNotNil(vc.presentedChild)
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

private class ViewController: UIViewController {
  override func viewDidLoad() {
    view.backgroundColor = .init(
      red: .random(in: 0...1),
      green: .random(in: 0...1),
      blue: .random(in: 0...1),
      alpha: 1
    )
    super.viewDidLoad()
  }
}

private class BasicViewController: UIViewController {
  @UIBindable var model: Model
  var isPresenting = false
  init(model: Model = Model()) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    view.backgroundColor = .init(
      red: .random(in: 0...1),
      green: .random(in: 0...1),
      blue: .random(in: 0...1),
      alpha: 1
    )
    super.viewDidLoad()
    present(isPresented: $model.isPresented) { [weak self] in
      self?.isPresenting = false
    } content: { [weak self] in
      self?.isPresenting = true
      return ViewController()
    }
    present(item: $model.presentedChild) { [weak self] in
      self?.isPresenting = false
    } content: { [weak self] model in
      self?.isPresenting = true
      return BasicViewController(model: model)
    }
    navigationDestination(isPresented: $model.isPushed) {
      ViewController()
    }
    navigationDestination(item: $model.pushedChild) { model in
      BasicViewController(model: model)
    }
  }
}
