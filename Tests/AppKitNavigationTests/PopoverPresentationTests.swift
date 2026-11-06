#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// Popovers shown from a view through `NSView.popover`.
  final class PopoverPresentationTests: XCTestCase {
    override func setUp() {
      super.setUp()
      MainActor.assumeIsolated {
        _ = NSApplication.shared
      }
    }

    @MainActor
    func testSettingTheBindingToTrueShowsThePopover() {
      let host = makeHost()
      let recorder = recordShownPopovers()
      @UIBinding var isPresented = false
      host.view.popover(isPresented: $isPresented) { self.makeViewController() }

      isPresented = true

      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true }, "The popover never appeared"
      )
    }

    @MainActor
    func testSettingTheBindingToFalseClosesThePopover() throws {
      let host = makeHost()
      let recorder = recordShownPopovers()
      @UIBinding var isPresented = false
      host.view.popover(isPresented: $isPresented) { self.makeViewController() }

      isPresented = true
      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true }, "The popover never appeared"
      )
      let popover = try XCTUnwrap(recorder.shownPopovers.first)

      isPresented = false

      XCTAssertTrue(waitUntil { !popover.isShown }, "The popover was not closed")
    }

    @MainActor
    func testUserClosingThePopoverWritesFalseBack() throws {
      let host = makeHost()
      let recorder = recordShownPopovers()
      @UIBinding var isPresented = false
      host.view.popover(isPresented: $isPresented) { self.makeViewController() }

      isPresented = true
      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true }, "The popover never appeared"
      )
      let popover = try XCTUnwrap(recorder.shownPopovers.first)

      // What a click outside a transient popover does.
      popover.close()

      XCTAssertTrue(waitUntil { !isPresented }, "Closing the popover did not write 'false' back")
    }

    @MainActor
    func testPopoverCanBeShownAgainAfterTheUserClosedIt() throws {
      let host = makeHost()
      let recorder = recordShownPopovers()
      @UIBinding var isPresented = false
      host.view.popover(isPresented: $isPresented) { self.makeViewController() }

      isPresented = true
      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true }, "The popover never appeared"
      )
      try XCTUnwrap(recorder.shownPopovers.first).close()
      XCTAssertTrue(waitUntil { !isPresented }, "Closing the popover did not write 'false' back")

      isPresented = true

      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.count == 2 && recorder.shownPopovers[1].isShown },
        "Setting the binding to 'true' again did not show the popover again"
      )
    }

    @MainActor
    func testUserClosingThePopoverCallsOnDismissOnce() throws {
      let host = makeHost()
      let recorder = recordShownPopovers()
      @UIBinding var isPresented = false
      var dismissCount = 0
      host.view.popover(isPresented: $isPresented, onDismiss: { dismissCount += 1 }) {
        self.makeViewController()
      }

      isPresented = true
      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true }, "The popover never appeared"
      )
      try XCTUnwrap(recorder.shownPopovers.first).close()
      XCTAssertTrue(waitUntil { !isPresented }, "Closing the popover did not write 'false' back")
      spinRunLoop(for: 0.3)

      XCTExpectFailure(
        """
        The popover is released as soon as it closes, before 'observe' re-runs, and 'onDismiss' only \
        runs from that re-run
        """
      ) {
        XCTAssertEqual(dismissCount, 1, "'onDismiss' did not run once the user closed the popover")
      }
    }

    @MainActor
    func testChangingTheItemClosesThePreviousPopover() throws {
      struct Item: Identifiable {
        let id: Int
      }
      let host = makeHost()
      let recorder = recordShownPopovers()
      @UIBinding var item: Item?
      host.view.popover(item: $item, behavior: .applicationDefined) { _ in
        self.makeViewController()
      }

      item = Item(id: 1)
      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true },
        "The first item's popover never appeared"
      )
      let firstPopover = try XCTUnwrap(recorder.shownPopovers.first)
      item = Item(id: 2)
      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.count == 2 && recorder.shownPopovers[1].isShown },
        "The second item's popover never appeared"
      )
      spinRunLoop(for: 0.5)

      XCTExpectFailure("Showing the next item's popover leaves the previous one open") {
        XCTAssertFalse(firstPopover.isShown, "The previous item's popover is still open")
      }
    }
  }
#endif
