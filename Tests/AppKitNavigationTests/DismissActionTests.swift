#if canImport(AppKit) && !targetEnvironment(macCatalyst) && AppKitPlus
  import AppKit
  import AppKitNavigation
  import AppKitPlus
  import XCTest

  /// Content that a binding showed can close itself with `traitCollection.dismiss()`, which ends
  /// it the way the user would: the binding is cleared, and `onDismiss` runs once.
  final class DismissActionTests: XCTestCase {
    override func setUp() {
      super.setUp()
      MainActor.assumeIsolated {
        _ = NSApplication.shared
      }
    }

    @MainActor
    func testAPresentedViewControllerDismissesItself() {
      let host = makeHost()
      let child = makeViewController()
      @UIBinding var isPresented = false
      let dismissCount = Recorded(0)
      host.viewController.present(
        isPresented: $isPresented, style: .sheet, onDismiss: { dismissCount.value += 1 }
      ) { child }

      isPresented = true
      XCTAssertTrue(waitUntil { child.view.window?.isVisible == true }, "The sheet never appeared")
      spinRunLoop(for: 0.1)

      child.traitCollection.dismiss()

      XCTAssertTrue(waitUntil { !isPresented }, "Dismissing did not write 'false' back")
      XCTAssertTrue(waitUntil { dismissCount.value == 1 })
    }

    @MainActor
    func testAWindowSheetDismissesItselfFromItsContent() {
      let host = makeHost()
      let sheetWindow = makeWindow()
      let contentView = NSView()
      sheetWindow.contentView = contentView
      @UIBinding var isPresented = false
      host.window.sheet(isPresented: $isPresented) { sheetWindow }

      isPresented = true
      XCTAssertTrue(waitUntil { sheetWindow.isVisible }, "The sheet never appeared")
      spinRunLoop(for: 0.1)

      contentView.traitCollection.dismiss()

      XCTAssertTrue(waitUntil { !isPresented }, "Dismissing did not write 'false' back")
      XCTAssertTrue(waitUntil { !sheetWindow.isVisible })
    }

    @MainActor
    func testAPopoverDismissesItself() {
      let host = makeHost()
      let content = makeViewController()
      @UIBinding var isPresented = false
      let popovers = recordShownPopovers()
      host.view.popover(isPresented: $isPresented, preferredEdge: .maxY) { content }

      isPresented = true
      XCTAssertTrue(waitUntil { popovers.shownPopovers.last?.isShown == true })
      spinRunLoop(for: 0.1)

      content.traitCollection.dismiss()

      XCTAssertTrue(waitUntil { !isPresented }, "Dismissing did not write 'false' back")
    }

    @MainActor
    func testAModalSessionWindowDismissesItself() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isPresented = false
      host.modalSession(isPresented: $isPresented) { window }

      isPresented = true
      XCTAssertTrue(waitUntil { window.isVisible }, "The window never appeared")
      spinRunLoop(for: 0.1)

      window.traitCollection.dismiss()

      XCTAssertTrue(waitUntil { !isPresented }, "Dismissing did not write 'false' back")
    }

    @MainActor
    func testAModalWindowDismissesItself() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isPresented = false
      host.modal(isPresented: $isPresented) { window }
      abortModalLoops(after: 5)

      let start = Date()
      perform(after: 0.5) {
        window.traitCollection.dismiss()
      }
      isPresented = true

      XCTAssertTrue(waitUntil(timeout: 4) { !isPresented }, "Dismissing did not write 'false' back")
      XCTAssertLessThan(
        Date().timeIntervalSince(start), 3,
        "The modal loop only ended when the safety timer aborted it"
      )
    }

    @MainActor
    func testContentThatNoBindingShowedReportsAnIssue() {
      let viewController = makeViewController()

      XCTExpectFailure {
        viewController.traitCollection.dismiss()
      }
      XCTAssertFalse(viewController.traitCollection.isPresented)
    }
  }
#endif
