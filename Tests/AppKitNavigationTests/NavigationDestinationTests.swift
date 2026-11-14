#if canImport(AppKit) && !targetEnvironment(macCatalyst) && AppKitPlus
  import AppKit
  import AppKitNavigation
  import AppKitPlus
  import XCTest

  /// A navigation destination is pushed while its binding holds a value, popped when it no longer
  /// does, and writes `nil` back when the user goes back past it or it dismisses itself.
  final class NavigationDestinationTests: XCTestCase {
    @MainActor
    func testPushesWhileTheItemHoldsAValueAndPopsWhenItBecomesNil() {
      let (navigationController, root) = makeNavigationController()
      @UIBinding var detail: Detail? = nil
      let dismissCount = Recorded(0)
      root.navigationDestination(item: $detail, onDismiss: { dismissCount.value += 1 }) { detail in
        DetailViewController(name: detail.name)
      }

      withoutAnimation { detail = Detail(name: "Mars") }
      XCTAssertTrue(waitUntil { navigationController.viewControllers.count == 2 })
      XCTAssertEqual(topName(of: navigationController), "Mars")

      withoutAnimation { detail = nil }
      XCTAssertTrue(waitUntil { navigationController.viewControllers.count == 1 })
      XCTAssertTrue(waitUntil { dismissCount.value == 1 })
    }

    /// The back button, ⌘↑ and the swipe all pop through the navigation controller.
    @MainActor
    func testGoingBackWritesNilBack() {
      let (navigationController, root) = makeNavigationController()
      @UIBinding var detail: Detail? = nil
      let dismissCount = Recorded(0)
      root.navigationDestination(item: $detail, onDismiss: { dismissCount.value += 1 }) { detail in
        DetailViewController(name: detail.name)
      }
      withoutAnimation { detail = Detail(name: "Mars") }
      XCTAssertTrue(waitUntil { navigationController.viewControllers.count == 2 })

      navigationController.popViewController(animated: false)

      XCTAssertTrue(waitUntil { detail == nil })
      XCTAssertTrue(waitUntil { dismissCount.value == 1 })
    }

    @MainActor
    func testANewItemReplacesTheDestination() {
      let (navigationController, root) = makeNavigationController()
      @UIBinding var detail: Detail? = nil
      let dismissCount = Recorded(0)
      root.navigationDestination(item: $detail, onDismiss: { dismissCount.value += 1 }) { detail in
        DetailViewController(name: detail.name)
      }
      withoutAnimation { detail = Detail(name: "Mars") }
      XCTAssertTrue(waitUntil { topName(of: navigationController) == "Mars" })

      withoutAnimation { detail = Detail(name: "Venus") }

      XCTAssertTrue(waitUntil { topName(of: navigationController) == "Venus" })
      XCTAssertEqual(navigationController.viewControllers.count, 2)
      XCTAssertEqual(dismissCount.value, 1)
    }

    @MainActor
    func testABooleanBindingPushesAndPops() {
      let (navigationController, root) = makeNavigationController()
      @UIBinding var isShowingSettings = false
      root.navigationDestination(isPresented: $isShowingSettings) {
        DetailViewController(name: "Settings")
      }

      withoutAnimation { isShowingSettings = true }
      XCTAssertTrue(waitUntil { topName(of: navigationController) == "Settings" })

      navigationController.popViewController(animated: false)
      XCTAssertTrue(waitUntil { !isShowingSettings })
    }

    @MainActor
    func testAPushedDestinationDismissesItself() {
      let (navigationController, root) = makeNavigationController()
      @UIBinding var detail: Detail? = nil
      let dismissCount = Recorded(0)
      root.navigationDestination(item: $detail, onDismiss: { dismissCount.value += 1 }) { detail in
        DetailViewController(name: detail.name)
      }
      withoutAnimation { detail = Detail(name: "Mars") }
      XCTAssertTrue(waitUntil { navigationController.viewControllers.count == 2 })
      // NB: AppKitPlus hands traits down to the view controllers inside on the next turn of the run
      //     loop.
      spinRunLoop(for: 0.1)

      withoutAnimation { navigationController.viewControllers[1].traitCollection.dismiss() }

      XCTAssertTrue(waitUntil { detail == nil })
      XCTAssertTrue(waitUntil { navigationController.viewControllers.count == 1 })
      XCTAssertTrue(waitUntil { dismissCount.value == 1 })
    }

    // MARK: - Support

    @MainActor
    private func makeNavigationController() -> (NSNavigationController, NSViewController) {
      let root = makeViewController()
      let navigationController = NSNavigationController(rootViewController: root)
      let window = makeWindow(width: 400, height: 300)
      window.contentViewController = navigationController
      window.orderFront(nil)
      _ = waitUntil { root.viewIfLoaded?.window != nil }
      return (navigationController, root)
    }

    @MainActor
    private func topName(of navigationController: NSNavigationController) -> String? {
      (navigationController.viewControllers.last as? DetailViewController)?.name
    }

    @MainActor
    private func withoutAnimation(_ body: () -> Void) {
      var transaction = UITransaction()
      transaction.appKit.disablesAnimations = true
      withUITransaction(transaction, body)
    }
  }

  private struct Detail: Identifiable {
    let name: String
    var id: String { name }
  }

  private final class DetailViewController: NSViewController {
    let name: String

    init(name: String) {
      self.name = name
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
#endif
