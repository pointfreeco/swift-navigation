#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// Popovers shown from a view through `NSView.popover`, and from a toolbar item through
  /// `NSToolbarItem.popover`.
  final class PopoverPresentationTests: XCTestCase {
    override func setUp() {
      super.setUp()
      MainActor.assumeIsolated {
        _ = NSApplication.shared
      }
    }

    // MARK: - View anchor

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

      XCTAssertEqual(dismissCount, 1, "'onDismiss' did not run once the user closed the popover")
    }

    @MainActor
    func testOnDismissRunsOnceThePopoverHasClosed() throws {
      let host = makeHost()
      let recorder = recordShownPopovers()
      @UIBinding var isPresented = false
      var popoverWasShownAtDismiss: Bool?
      host.view.popover(
        isPresented: $isPresented,
        onDismiss: { popoverWasShownAtDismiss = recorder.shownPopovers.first?.isShown }
      ) {
        self.makeViewController()
      }

      isPresented = true
      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true }, "The popover never appeared"
      )
      isPresented = false
      XCTAssertTrue(waitUntil { popoverWasShownAtDismiss != nil }, "'onDismiss' never ran")

      XCTAssertEqual(popoverWasShownAtDismiss, false, "'onDismiss' ran while the popover was open")
    }

    @MainActor
    func testChangingTheItemClosesThePreviousPopover() throws {
      struct Item: Identifiable {
        let id: Int
      }
      let host = makeHost()
      let recorder = recordShownPopovers()
      @UIBinding var item: Item?
      var dismissCount = 0
      host.view.popover(
        item: $item, behavior: .applicationDefined, onDismiss: { dismissCount += 1 }
      ) { _ in
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

      XCTAssertFalse(firstPopover.isShown, "The previous item's popover is still open")
      XCTAssertEqual(dismissCount, 1, "'onDismiss' did not run exactly once for the first item")
    }

    @MainActor
    func testPopoverWaitsUntilItsWindowIsOnScreen() {
      let viewController = makeViewController(width: 480, height: 320)
      let window = NSWindow(contentViewController: viewController)
      window.isReleasedWhenClosed = false
      addTeardownBlock { @MainActor in
        window.close()
      }
      let recorder = recordShownPopovers()
      // Already 'true' when the popover is set up, before the window is on screen.
      @UIBinding var isPresented = true
      viewController.view.popover(isPresented: $isPresented) { self.makeViewController() }
      spinRunLoop(for: 0.3)
      XCTAssertTrue(recorder.shownPopovers.isEmpty, "The popover showed for a window off screen")

      window.orderFront(nil)

      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true },
        "The popover never appeared once the window was on screen"
      )
    }

    @MainActor
    func testPopoverWaitsUntilItsViewIsInAWindow() {
      let host = makeHost()
      let anchorView = NSView(frame: NSRect(x: 20, y: 20, width: 80, height: 24))
      let recorder = recordShownPopovers()
      @UIBinding var isPresented = true
      anchorView.popover(isPresented: $isPresented) { self.makeViewController() }
      spinRunLoop(for: 0.3)
      XCTAssertTrue(recorder.shownPopovers.isEmpty, "The popover showed for a view in no window")

      host.view.addSubview(anchorView)

      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true },
        "The popover never appeared once the view was in a window"
      )
    }

    @MainActor
    func testATransactionThatDisablesAnimationsShowsThePopoverWithoutAnimating() throws {
      let host = makeHost()
      let recorder = recordShownPopovers()
      @UIBinding var isPresented = false
      host.view.popover(isPresented: $isPresented) { self.makeViewController() }

      withUITransaction(\.appKit.disablesAnimations, true) {
        isPresented = true
      }

      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true }, "The popover never appeared"
      )
      XCTAssertFalse(try XCTUnwrap(recorder.shownPopovers.first).animates)
    }

    // MARK: - Toolbar item anchor

    @available(macOS 14.0, *)
    @MainActor
    func testSettingTheBindingToTrueShowsAToolbarItemsPopover() {
      let toolbarHost = makeToolbarHost()
      let recorder = recordShownPopovers()
      @UIBinding var isPresented = false
      toolbarHost.item.popover(isPresented: $isPresented) { self.makeViewController() }
      toolbarHost.window.orderFront(nil)

      isPresented = true

      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true },
        "The toolbar item's popover never appeared"
      )
      isPresented = false
      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == false },
        "The toolbar item's popover was not closed"
      )
    }

    @available(macOS 14.0, *)
    @MainActor
    func testToolbarItemsPopoverWaitsUntilItsWindowIsOnScreen() {
      let toolbarHost = makeToolbarHost()
      let recorder = recordShownPopovers()
      @UIBinding var isPresented = true
      toolbarHost.item.popover(isPresented: $isPresented) { self.makeViewController() }
      spinRunLoop(for: 0.3)
      XCTAssertTrue(recorder.shownPopovers.isEmpty, "The popover showed for a window off screen")

      toolbarHost.window.orderFront(nil)

      XCTAssertTrue(
        waitUntil { recorder.shownPopovers.first?.isShown == true },
        "The toolbar item's popover never appeared once its window was on screen"
      )
    }

    // MARK: - Support

    @MainActor
    private struct ToolbarHost {
      let window: NSWindow
      let item: NSToolbarItem
    }

    /// A window, not yet on screen, whose toolbar shows a single item.
    @MainActor
    private func makeToolbarHost() -> ToolbarHost {
      let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("Info"))
      item.label = "Info"
      item.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "Info")
      let delegate = SingleItemToolbarDelegate(item: item)
      let toolbar = NSToolbar(identifier: "PopoverPresentationTests")
      toolbar.delegate = delegate
      let window = makeWindow(width: 480, height: 320)
      window.styleMask.insert(.resizable)
      window.toolbar = toolbar
      addTeardownBlock { @MainActor in
        // NB: The toolbar does not keep its delegate.
        _ = delegate
      }
      return ToolbarHost(window: window, item: item)
    }
  }

  @MainActor
  private final class SingleItemToolbarDelegate: NSObject, NSToolbarDelegate {
    let item: NSToolbarItem

    init(item: NSToolbarItem) {
      self.item = item
    }

    func toolbar(
      _ toolbar: NSToolbar,
      itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
      willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
      itemIdentifier == item.itemIdentifier ? item : nil
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
      [item.itemIdentifier]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
      [item.itemIdentifier]
    }
  }
#endif
