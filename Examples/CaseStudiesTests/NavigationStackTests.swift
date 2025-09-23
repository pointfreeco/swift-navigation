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

  @MainActor
  func testInteractivePopAction() async throws {
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

    let secondVC = nav.viewControllers.last!

    let interactionController = UIPercentDrivenInteractiveTransition()
    let delegate = MockNavigationControllerDelegate()

    nav.delegate = delegate
    // Simulate beginning interactive pop
    delegate.interactionController = interactionController

    // The gesture begins (simulate by calling delegate)
    let animationController = delegate.navigationController(
      nav,
      animationControllerFor: .pop,
      from: secondVC,
      to: nav.viewControllers.first!
    )!

    let returnedInteraction = delegate.navigationController(
      nav,
      interactionControllerFor: animationController
    )

    // Test: The interaction controller is returned and did not immediately finish
    XCTAssertTrue(delegate.didCallInteractionController, "Delegate method should have been called")
    XCTAssertNotNil(returnedInteraction, "Should return the interaction controller")

    // Verify that the interaction has not yet finished
    XCTAssertFalse(interactionController.percentComplete >= 1.0, "Interaction should not automatically finish")
  }

  @MainActor
  func testInteractivePopViaGestureAction() async throws {
    @UIBinding var path = [Int]()
    let nav = NavigationStackController(path: $path) {
      UIViewController()
    }
    nav.navigationDestination(for: Int.self) { number in
      ChildViewController(number: number)
    }
    try await setUp(controller: nav)
    try await Task.sleep(for: .seconds(1))

    nav.traitCollection.push(value: 1)
    await assertEventuallyEqual(nav.viewControllers.count, 2)
    await assertEventuallyEqual(path, [1])

    let interaction = MockPercentDrivenInteractiveTransition()
    let delegate = MockNavigationControllerDelegate()
    delegate.interactionController = interaction
    nav.delegate = delegate

    let interactionExpectation = expectation(
      description: "navigationController(_:interactionControllerFor:) called"
    )
    delegate.interactionExpectation = interactionExpectation

    await MainActor.run {
      _ = nav.popViewController(animated: true)
    }

    await fulfillment(of: [interactionExpectation], timeout: 1.0)

    XCTAssertTrue(delegate.didCallInteractionController)
    XCTAssertFalse(interaction.didCallFinish)
    XCTAssertFalse(interaction.didCallCancel)

    await MainActor.run {
      interaction.update(0.5)
      interaction.finish()
    }

    let predicate = NSPredicate(format: "viewControllers.@count == 1")
    let vcCountExpectation = XCTNSPredicateExpectation(
      predicate: predicate,
      object: nav
    )
    await fulfillment(of: [vcCountExpectation], timeout: 2.0)

    XCTAssertTrue(interaction.didCallFinish)
    XCTAssertFalse(interaction.didCallCancel)
    XCTAssertEqual(nav.viewControllers.count, 1)
  }
}

class MockPercentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition {
  private(set) var didCallFinish = false
  private(set) var didCallCancel = false

  override func finish() {
    super.finish()
    didCallFinish = true
  }

  override func cancel() {
    super.cancel()
    didCallCancel = true
  }
}

final class MockAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  let duration: TimeInterval

  init(duration: TimeInterval = 0.25) {
    self.duration = duration
    super.init()
  }

  func transitionDuration(
    using transitionContext: UIViewControllerContextTransitioning?
  ) -> TimeInterval {
    return duration
  }

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    // Basic animation that moves the fromView out and the toView in.
    guard
      let container = transitionContext.containerView as UIView?,
      let fromVC = transitionContext.viewController(forKey: .from),
      let toVC = transitionContext.viewController(forKey: .to)
    else {
      transitionContext.completeTransition(false)
      return
    }

    let fromView = fromVC.view!
    let toView = toVC.view!

    // Place toView below and set starting frame
    let initialFrame = transitionContext.initialFrame(for: fromVC)
    toView.frame = initialFrame.offsetBy(dx: initialFrame.width, dy: 0)
    container.addSubview(toView)

    UIView.animate(
      withDuration: transitionDuration(using: transitionContext),
      delay: 0,
      options: [.curveLinear]
    ) {
      fromView.frame = initialFrame.offsetBy(dx: -initialFrame.width / 3.0, dy: 0)
      toView.frame = initialFrame
    } completion: { finished in
      let cancelled = transitionContext.transitionWasCancelled
      transitionContext.completeTransition(!cancelled)
    }
  }
}


final class MockNavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
  var interactionController: UIPercentDrivenInteractiveTransition?
  var interactionExpectation: XCTestExpectation?
  var didCallInteractionController = false

  func navigationController(
    _ navigationController: UINavigationController,
    animationControllerFor operation: UINavigationController.Operation,
    from fromVC: UIViewController,
    to toVC: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    return MockAnimator()
  }

  func navigationController(
    _ navigationController: UINavigationController,
    interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
  ) -> UIViewControllerInteractiveTransitioning? {
    didCallInteractionController = true
    DispatchQueue.main.async { [weak self] in
      self?.interactionExpectation?.fulfill()
    }
    return interactionController
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
