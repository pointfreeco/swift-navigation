#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// Presentations whose content is a view controller, through `present(isPresented:style:)` and
  /// `sheet(isSheeted:)`.
  ///
  /// These run as synchronous XCTest methods on purpose: they wait by spinning the main run loop,
  /// which is what drives sheet animations, window ordering and the main-queue re-runs of
  /// `observe`.
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
      let sheetViewController = makeContentViewController()
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
        self.makeContentViewController()
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
        self.makeContentViewController()
      }

      isPresented = true
      XCTAssertTrue(waitUntil { host.window.attachedSheet != nil }, "The sheet never appeared")

      isPresented = false

      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The sheet was not dismissed")
    }

    @MainActor
    func testViewControllerSheetStaysPresentedUntilItIsDismissed() {
      let host = makeHost()
      @UIBinding var isSheeted = false
      host.viewController.sheet(isSheeted: $isSheeted) {
        self.makeContentViewController()
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
      let sheetViewController = makeContentViewController()
      host.viewController.sheet(isSheeted: $isSheeted) { sheetViewController }

      isSheeted = true
      XCTAssertTrue(waitUntil { host.window.attachedSheet != nil }, "The sheet never appeared")
      spinRunLoop(for: 0.5)

      sheetViewController.dismiss(nil)

      XCTAssertTrue(waitUntil { !isSheeted }, "Dismissing the sheet did not write 'false' back")
    }

    // MARK: - Support

    @MainActor
    private struct Host {
      let window: NSWindow
      let viewController: NSViewController
    }

    @MainActor
    private func makeHost() -> Host {
      let viewController = makeContentViewController(width: 480, height: 320)
      let window = NSWindow(contentViewController: viewController)
      window.isReleasedWhenClosed = false
      window.orderFront(nil)
      addTeardownBlock { @MainActor in
        if let attachedSheet = window.attachedSheet {
          window.endSheet(attachedSheet)
        }
        window.close()
      }
      return Host(window: window, viewController: viewController)
    }

    @MainActor
    private func makeContentViewController(
      width: CGFloat = 200, height: CGFloat = 120
    ) -> NSViewController {
      let viewController = NSViewController()
      viewController.view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
      return viewController
    }

    @MainActor
    private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) -> Bool {
      let deadline = Date(timeIntervalSinceNow: timeout)
      while !condition(), Date() < deadline {
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
      }
      return condition()
    }

    @MainActor
    private func spinRunLoop(for duration: TimeInterval) {
      let deadline = Date(timeIntervalSinceNow: duration)
      while Date() < deadline {
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
      }
    }
  }
#endif
