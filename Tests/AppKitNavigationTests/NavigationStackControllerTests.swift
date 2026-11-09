#if canImport(AppKit) && !targetEnvironment(macCatalyst) && AppKitPlus
  import AppKit
  import AppKitNavigation
  #if compiler(<6.4)
    // NB: Swift 6.2 treats the delegate's conformance below as public, and a public conformance
    //     needs a public import.
    public import AppKitPlus
  #else
    import AppKitPlus
  #endif
  import XCTest

  /// A navigation stack controller pushes and pops view controllers as its path changes, and
  /// writes the path back when the user goes back or content dismisses itself.
  final class NavigationStackControllerTests: XCTestCase {
    @MainActor
    func testChangingThePathPushesAndPopsViewControllers() {
      @UIBinding var path: [Int] = []
      let stackController = makeStackController(path: $path)

      withoutAnimation { path = [1] }
      XCTAssertTrue(waitUntil { stackController.viewControllers.count == 2 })
      XCTAssertEqual(numbers(in: stackController), [1])

      withoutAnimation { path = [1, 2, 3] }
      XCTAssertTrue(waitUntil { stackController.viewControllers.count == 4 })
      XCTAssertEqual(numbers(in: stackController), [1, 2, 3])

      withoutAnimation { path = [1] }
      XCTAssertTrue(waitUntil { stackController.viewControllers.count == 2 })

      withoutAnimation { path = [] }
      XCTAssertTrue(waitUntil { stackController.viewControllers.count == 1 })
    }

    @MainActor
    func testStartsWithTheViewControllersOfThePath() {
      @UIBinding var path = [4, 5]
      let stackController = makeStackController(path: $path)

      XCTAssertTrue(waitUntil { stackController.viewControllers.count == 3 })
      XCTAssertEqual(numbers(in: stackController), [4, 5])
    }

    /// The back button, ⌘↑ and the swipe all pop through the navigation controller.
    @MainActor
    func testGoingBackTrimsThePath() {
      @UIBinding var path = [1, 2]
      let stackController = makeStackController(path: $path)
      XCTAssertTrue(waitUntil { stackController.viewControllers.count == 3 })

      stackController.popViewController(animated: false)

      XCTAssertTrue(waitUntil { path == [1] })
    }

    @MainActor
    func testPushingAValueAppendsItToThePath() throws {
      @UIBinding var path: [Int] = []
      let stackController = makeStackController(path: $path)
      let root = try XCTUnwrap(stackController.viewControllers.first)
      // NB: AppKitPlus hands traits down to the view controllers inside on the next turn of the run
      //     loop.
      spinRunLoop(for: 0.1)

      root.traitCollection.push(value: 7)

      XCTAssertEqual(path, [7])
      XCTAssertTrue(waitUntil { stackController.viewControllers.count == 2 })
    }

    @MainActor
    func testDismissingAPushedViewControllerPopsIt() {
      @UIBinding var path = [1, 2]
      let stackController = makeStackController(path: $path)
      XCTAssertTrue(waitUntil { stackController.viewControllers.count == 3 })

      stackController.viewControllers[2].traitCollection.dismiss()

      XCTAssertTrue(waitUntil { path == [1] })
      XCTAssertTrue(waitUntil { stackController.viewControllers.count == 2 })
    }

    @MainActor
    func testTheAppsDelegateStillHearsFromTheNavigationController() {
      @UIBinding var path: [Int] = []
      let stackController = makeStackController(path: $path)
      let delegate = ShowRecordingDelegate()
      stackController.delegate = delegate

      withoutAnimation { path = [1] }

      XCTAssertTrue(waitUntil { delegate.shownCount > 0 })
    }

    // MARK: - Support

    @MainActor
    private func makeStackController(path: UIBinding<[Int]>) -> NavigationStackController {
      let stackController = NavigationStackController(path: path) { [unowned self] in
        makeViewController()
      }
      stackController.navigationDestination(for: Int.self) { number in
        NumberViewController(number: number)
      }
      let window = makeWindow(width: 400, height: 300)
      window.contentViewController = stackController
      window.orderFront(nil)
      return stackController
    }

    @MainActor
    private func numbers(in stackController: NavigationStackController) -> [Int] {
      stackController.viewControllers.compactMap { ($0 as? NumberViewController)?.number }
    }

    @MainActor
    private func withoutAnimation(_ body: () -> Void) {
      var transaction = UITransaction()
      transaction.appKit.disablesAnimations = true
      withUITransaction(transaction, body)
    }
  }

  private final class NumberViewController: NSViewController {
    let number: Int

    init(number: Int) {
      self.number = number
      super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
      view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 120))
    }
  }

  private final class ShowRecordingDelegate: NSObject, NSNavigationControllerDelegate {
    private(set) var shownCount = 0

    func navigationController(
      _ navigationController: NSNavigationController,
      didShow viewController: NSViewController
    ) {
      shownCount += 1
    }
  }
#endif
