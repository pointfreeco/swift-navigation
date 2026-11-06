#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// Presentations whose content is a view controller, through `present(isPresented:style:)` and
  /// `sheet(isSheeted:)`.
  final class ViewControllerPresentationTests: XCTestCase {
    override func setUp() {
      super.setUp()
      MainActor.assumeIsolated {
        _ = NSApplication.shared
      }
    }

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
    func testPresentingLeavesAnotherBindingsPresentationInPlace() {
      let host = makeHost()
      let firstViewController = makeViewController()
      @UIBinding var isFirstPresented = false
      @UIBinding var isSecondPresented = false
      var secondDismissCount = 0
      host.viewController.present(isPresented: $isFirstPresented, style: .sheet) {
        firstViewController
      }
      host.viewController.present(
        isPresented: $isSecondPresented, style: .sheet, onDismiss: { secondDismissCount += 1 }
      ) {
        self.makeViewController()
      }

      isFirstPresented = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet?.contentViewController === firstViewController },
        "The first sheet never appeared"
      )
      isSecondPresented = true
      spinRunLoop(for: 0.5)

      XCTExpectFailure(
        "present(…) dismisses whatever view controller is presented, and calls its own onDismiss for it"
      ) {
        XCTAssertTrue(isFirstPresented, "Presenting the second sheet dismissed the first binding's sheet")
        XCTAssertEqual(
          secondDismissCount, 0,
          "The second binding's 'onDismiss' ran for a sheet it never presented"
        )
      }

      isFirstPresented = false
      isSecondPresented = false
      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The sheets never went away")
    }

    @MainActor
    func testViewControllerSheetStaysPresentedUntilItIsDismissed() {
      let host = makeHost()
      @UIBinding var isSheeted = false
      host.viewController.sheet(isSheeted: $isSheeted) {
        self.makeViewController()
      }

      isSheeted = true
      XCTAssertTrue(waitUntil { host.window.attachedSheet != nil }, "The sheet never appeared")
      spinRunLoop(for: 0.5)

      XCTAssertTrue(isSheeted, "The sheet dismissed itself right after it appeared")
    }

    @MainActor
    func testUserDismissingAViewControllerSheetWritesFalseBack() {
      let host = makeHost()
      @UIBinding var isSheeted = false
      let sheetViewController = makeViewController()
      host.viewController.sheet(isSheeted: $isSheeted) { sheetViewController }

      isSheeted = true
      XCTAssertTrue(waitUntil { host.window.attachedSheet != nil }, "The sheet never appeared")
      spinRunLoop(for: 0.5)

      sheetViewController.dismiss(nil)

      XCTAssertTrue(waitUntil { !isSheeted }, "Dismissing the sheet did not write 'false' back")
    }
  }
#endif
