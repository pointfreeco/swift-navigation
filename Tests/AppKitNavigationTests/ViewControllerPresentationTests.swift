#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// Presentations whose content is a view controller, through `present(isPresented:style:)` and
  /// `destination(isPresented:content:present:dismiss:)`.
  final class ViewControllerPresentationTests: XCTestCase {
    override func setUp() {
      super.setUp()
      MainActor.assumeIsolated {
        _ = NSApplication.shared
      }
    }

    // MARK: - Sheet style

    @MainActor
    func testUserDismissingAPresentedSheetWritesFalseBack() {
      let host = makeHost()
      @UIBinding var isPresented = false
      let sheetViewController = makeViewController()
      host.viewController.present(isPresented: $isPresented, style: .sheet) {
        sheetViewController
      }

      isPresented = true
      XCTAssertTrue(waitUntil { host.window.attachedSheet != nil }, "The sheet never appeared")

      // What a Cancel button wired to 'dismissController:' does.
      sheetViewController.dismiss(nil)

      XCTAssertTrue(waitUntil { !isPresented }, "Dismissing the sheet did not write 'false' back")
    }

    @MainActor
    func testUserDismissingAPresentedSheetCallsOnDismissOnce() {
      let host = makeHost()
      @UIBinding var isPresented = false
      var dismissCount = 0
      host.viewController.present(
        isPresented: $isPresented, style: .sheet, onDismiss: { dismissCount += 1 }
      ) {
        // NB: Made here, and held by nothing but the presentation.
        self.makeViewController()
      }

      isPresented = true
      XCTAssertTrue(waitUntil { host.window.attachedSheet != nil }, "The sheet never appeared")
      host.window.attachedSheet?.contentViewController?.dismiss(nil)
      XCTAssertTrue(waitUntil { !isPresented }, "Dismissing the sheet did not write 'false' back")
      spinRunLoop(for: 0.3)

      XCTAssertEqual(dismissCount, 1, "'onDismiss' did not run once the user dismissed the sheet")
    }

    // NB: The window's 'attachedSheet' can still point at a sheet that has already left the screen,
    //     so the sheet's own window is what tells.
    @MainActor
    func testOnDismissRunsOnceThePresentedSheetHasLeftTheScreen() throws {
      let host = makeHost()
      @UIBinding var isPresented = false
      var sheetWindow: NSWindow?
      var sheetWasVisibleAtDismiss: Bool?
      host.viewController.present(
        isPresented: $isPresented,
        style: .sheet,
        onDismiss: { sheetWasVisibleAtDismiss = sheetWindow?.isVisible }
      ) {
        self.makeViewController()
      }

      isPresented = true
      XCTAssertTrue(waitUntil { host.window.attachedSheet != nil }, "The sheet never appeared")
      sheetWindow = try XCTUnwrap(host.window.attachedSheet)
      isPresented = false
      XCTAssertTrue(waitUntil { sheetWasVisibleAtDismiss != nil }, "'onDismiss' never ran")

      XCTAssertEqual(sheetWasVisibleAtDismiss, false, "'onDismiss' ran while the sheet was on screen")
    }

    @MainActor
    func testPresentedSheetCanBePresentedAgainAfterTheUserDismissedIt() {
      let host = makeHost()
      @UIBinding var isPresented = false
      host.viewController.present(isPresented: $isPresented, style: .sheet) {
        self.makeViewController()
      }

      isPresented = true
      XCTAssertTrue(waitUntil { host.window.attachedSheet != nil }, "The sheet never appeared")
      host.window.attachedSheet?.contentViewController?.dismiss(nil)
      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The sheet never went away")

      // NB: No waiting here on purpose. The dismissal writes 'false' back synchronously, but
      //     'observe' only re-runs on a later turn of the main queue, so setting 'true' again
      //     straight away is exactly the case where the 'false' in between is never observed.
      isPresented = true

      XCTAssertTrue(
        waitUntil { host.window.attachedSheet != nil },
        "Setting the binding to 'true' again did not present the sheet again"
      )
    }

    @MainActor
    func testSettingTheBindingToFalseDismissesAPresentedSheet() {
      let host = makeHost()
      @UIBinding var isPresented = false
      host.viewController.present(isPresented: $isPresented, style: .sheet) {
        self.makeViewController()
      }

      isPresented = true
      XCTAssertTrue(waitUntil { host.window.attachedSheet != nil }, "The sheet never appeared")

      isPresented = false

      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The sheet was not dismissed")
    }

    // NB: 'sheet(isSheeted:)' once dismissed a view controller sheet the moment it appeared, while
    //     its own implementation of sheets still existed next to this one.
    @MainActor
    func testPresentedSheetStaysPresentedUntilItIsDismissed() {
      let host = makeHost()
      @UIBinding var isPresented = false
      host.viewController.present(isPresented: $isPresented, style: .sheet) {
        self.makeViewController()
      }

      isPresented = true
      XCTAssertTrue(waitUntil { host.window.attachedSheet != nil }, "The sheet never appeared")
      spinRunLoop(for: 0.5)

      XCTAssertTrue(isPresented, "The sheet dismissed itself right after it appeared")
    }

    @MainActor
    func testPresentedSheetWaitsUntilTheViewAppears() {
      let viewController = makeViewController(width: 480, height: 320)
      // Already 'true' when the presentation is set up, before the view is in any window.
      @UIBinding var isPresented = true
      viewController.present(isPresented: $isPresented, style: .sheet) {
        self.makeViewController()
      }
      spinRunLoop(for: 0.2)

      let window = NSWindow(contentViewController: viewController)
      window.isReleasedWhenClosed = false
      addTeardownBlock { @MainActor in
        while let attachedSheet = window.attachedSheet {
          window.endSheet(attachedSheet)
        }
        window.close()
      }
      window.orderFront(nil)

      XCTAssertTrue(
        waitUntil { window.attachedSheet != nil }, "The sheet never appeared once the view did"
      )
    }

    @MainActor
    func testChangingTheItemDismissesTheViewControllerBeforeTheNextOneIsPresented() {
      struct Item: Identifiable {
        let id: Int
      }
      let host = makeHost()
      let firstViewController = makeViewController()
      let secondViewController = makeViewController()
      @UIBinding var item: Item?
      var dismissCount = 0
      host.viewController.present(item: $item, style: .sheet, onDismiss: { dismissCount += 1 }) {
        currentItem in
        currentItem.id == 1 ? firstViewController : secondViewController
      }

      item = Item(id: 1)
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet?.contentViewController === firstViewController },
        "The first item's sheet never appeared"
      )
      item = Item(id: 2)
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet?.contentViewController === secondViewController },
        "The second item's sheet never took the first one's place"
      )

      XCTAssertNil(firstViewController.presentingViewController, "The first item's sheet is still up")
      XCTAssertEqual(dismissCount, 1, "'onDismiss' did not run exactly once for the first item")
      item = nil
      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The second sheet never went away")
    }

    @MainActor
    func testPresentingLeavesAnotherBindingsPresentationInPlace() {
      let host = makeHost()
      let firstViewController = makeViewController()
      let secondViewController = makeViewController()
      @UIBinding var isFirstPresented = false
      @UIBinding var isSecondPresented = false
      var secondDismissCount = 0
      host.viewController.present(isPresented: $isFirstPresented, style: .sheet) {
        firstViewController
      }
      host.viewController.present(
        isPresented: $isSecondPresented, style: .sheet, onDismiss: { secondDismissCount += 1 }
      ) {
        secondViewController
      }

      isFirstPresented = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet?.contentViewController === firstViewController },
        "The first sheet never appeared"
      )
      isSecondPresented = true
      spinRunLoop(for: 0.5)

      XCTAssertTrue(isFirstPresented, "Presenting the second sheet dismissed the first binding's sheet")
      XCTAssertEqual(
        secondDismissCount, 0, "The second binding's 'onDismiss' ran for a sheet it never presented"
      )

      isFirstPresented = false
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet?.contentViewController === secondViewController },
        "The queued sheet never appeared once the first one was dismissed"
      )
      isSecondPresented = false
      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The sheets never went away")
    }

    // MARK: - Modal window style

    @MainActor
    func testSettingTheBindingToFalseDismissesAModalWindow() {
      let host = makeHost()
      let presentedViewController = makeViewController()
      @UIBinding var isPresented = false
      host.viewController.present(isPresented: $isPresented, style: .modalWindow) {
        presentedViewController
      }
      abortModalLoops(after: 5)

      let start = Date()
      let wasOnScreen = Recorded(false)
      perform(after: 0.5) {
        wasOnScreen.value = presentedViewController.view.window?.isVisible == true
        isPresented = false
      }
      isPresented = true

      XCTAssertTrue(
        waitUntil(timeout: 4) { !isPresented && presentedViewController.view.window?.isVisible != true },
        "The modal window was not dismissed"
      )
      XCTAssertTrue(wasOnScreen.value, "The modal window never appeared")
      XCTAssertLessThan(
        Date().timeIntervalSince(start), 3,
        "The modal window only went away when the safety timer aborted it"
      )
    }

    // MARK: - Custom presentation

    @MainActor
    func testDestinationPresentsAndDismissesThroughTheGivenClosures() {
      let host = makeHost()
      @UIBinding var isPresented = false
      var presentedChildren: [NSViewController] = []
      var dismissedChildren: [NSViewController] = []
      host.viewController.destination(isPresented: $isPresented) {
        self.makeViewController()
      } present: { child, _ in
        host.viewController.addChild(child)
        host.view.addSubview(child.view)
        presentedChildren.append(child)
      } dismiss: { child, _ in
        child.view.removeFromSuperview()
        child.removeFromParent()
        dismissedChildren.append(child)
      }

      isPresented = true
      XCTAssertTrue(waitUntil { presentedChildren.count == 1 }, "The child was never presented")
      isPresented = false
      XCTAssertTrue(waitUntil { dismissedChildren.count == 1 }, "The child was never dismissed")
      XCTAssertTrue(dismissedChildren.first === presentedChildren.first)

      isPresented = true

      XCTAssertTrue(
        waitUntil { presentedChildren.count == 2 },
        "Setting the binding to 'true' again did not present the child again"
      )
    }
  }
#endif
