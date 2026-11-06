#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// Content attached to a window as a sheet through `NSWindow.sheet`: a window, an alert or a
  /// save panel.
  final class SheetPresentationTests: XCTestCase {
    override func setUp() {
      super.setUp()
      MainActor.assumeIsolated {
        _ = NSApplication.shared
      }
    }

    // MARK: - Window content

    @MainActor
    func testSettingTheBindingToTrueAttachesTheWindowAsASheet() {
      let host = makeHost()
      let sheetWindow = makeWindow()
      @UIBinding var isPresented = false
      host.window.sheet(isPresented: $isPresented) { sheetWindow }

      isPresented = true

      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === sheetWindow }, "The sheet never appeared"
      )
    }

    @MainActor
    func testSettingTheBindingToFalseEndsTheSheet() {
      let host = makeHost()
      let sheetWindow = makeWindow()
      @UIBinding var isPresented = false
      host.window.sheet(isPresented: $isPresented) { sheetWindow }

      isPresented = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === sheetWindow }, "The sheet never appeared"
      )

      isPresented = false

      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The sheet was not ended")
    }

    @MainActor
    func testUserEndingTheSheetWritesFalseBack() {
      let host = makeHost()
      let sheetWindow = makeWindow()
      @UIBinding var isPresented = false
      host.window.sheet(isPresented: $isPresented) { sheetWindow }

      isPresented = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === sheetWindow }, "The sheet never appeared"
      )

      // What a Cancel button in the sheet does.
      host.window.endSheet(sheetWindow)

      XCTAssertTrue(waitUntil { !isPresented }, "Ending the sheet did not write 'false' back")
    }

    @MainActor
    func testSettingTheBindingToFalseCallsOnDismissOnce() {
      let host = makeHost()
      let sheetWindow = makeWindow()
      @UIBinding var isPresented = false
      var dismissCount = 0
      host.window.sheet(isPresented: $isPresented, onDismiss: { dismissCount += 1 }) {
        sheetWindow
      }

      isPresented = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === sheetWindow }, "The sheet never appeared"
      )
      isPresented = false
      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The sheet was not ended")
      spinRunLoop(for: 0.3)

      XCTAssertEqual(dismissCount, 1)
    }

    @MainActor
    func testOnDismissRunsOnceTheSheetHasLeftTheScreen() {
      let host = makeHost()
      let sheetWindow = makeWindow()
      @UIBinding var isPresented = false
      var sheetWasVisibleAtDismiss: Bool?
      host.window.sheet(
        isPresented: $isPresented,
        onDismiss: { sheetWasVisibleAtDismiss = sheetWindow.isVisible }
      ) {
        sheetWindow
      }

      isPresented = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === sheetWindow }, "The sheet never appeared"
      )
      isPresented = false
      XCTAssertTrue(waitUntil { sheetWasVisibleAtDismiss != nil }, "'onDismiss' never ran")

      XCTAssertEqual(sheetWasVisibleAtDismiss, false, "'onDismiss' ran while the sheet was on screen")
    }

    @MainActor
    func testSheetWaitsUntilTheParentWindowIsShown() {
      let parentWindow = makeWindow(width: 480, height: 320)
      let sheetWindow = makeWindow()
      // Already 'true' when the sheet is set up, before the window is on screen.
      @UIBinding var isPresented = true
      parentWindow.sheet(isPresented: $isPresented) { sheetWindow }
      spinRunLoop(for: 0.3)
      XCTAssertNil(parentWindow.attachedSheet, "The sheet was attached to a window off screen")

      parentWindow.orderFront(nil)

      XCTAssertTrue(
        waitUntil { parentWindow.attachedSheet === sheetWindow },
        "The sheet never appeared once the window was on screen"
      )
      parentWindow.endSheet(sheetWindow)
    }

    @MainActor
    func testChangingTheItemEndsTheSheetBeforeTheNextOneIsAttached() {
      struct Item: Identifiable {
        let id: Int
      }
      let host = makeHost()
      let firstSheet = makeWindow()
      let secondSheet = makeWindow()
      @UIBinding var item: Item?
      var dismissCount = 0
      host.window.sheet(item: $item, onDismiss: { dismissCount += 1 }) { currentItem in
        currentItem.id == 1 ? firstSheet : secondSheet
      }

      item = Item(id: 1)
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === firstSheet }, "The first sheet never appeared"
      )
      item = Item(id: 2)
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === secondSheet },
        "The second item's sheet never took the first one's place"
      )

      XCTAssertFalse(firstSheet.isVisible, "The first item's sheet is still on screen")
      XCTAssertEqual(dismissCount, 1, "'onDismiss' did not run exactly once for the first item")
      item = nil
      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The second sheet never ended")
    }

    @MainActor
    func testPresentingASheetLeavesAnotherBindingsSheetInPlace() {
      let host = makeHost()
      let firstSheet = makeWindow()
      let secondSheet = makeWindow()
      @UIBinding var isFirstPresented = false
      @UIBinding var isSecondPresented = false
      var secondDismissCount = 0
      host.window.sheet(isPresented: $isFirstPresented) { firstSheet }
      host.window.sheet(isPresented: $isSecondPresented, onDismiss: { secondDismissCount += 1 }) {
        secondSheet
      }

      isFirstPresented = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === firstSheet }, "The first sheet never appeared"
      )
      isSecondPresented = true
      spinRunLoop(for: 0.5)

      XCTAssertTrue(isFirstPresented, "Presenting the second sheet ended the first binding's sheet")
      XCTAssertEqual(
        secondDismissCount, 0, "The second binding's 'onDismiss' ran for a sheet it never presented"
      )

      isFirstPresented = false
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === secondSheet },
        "The queued sheet never appeared once the first one ended"
      )
      isSecondPresented = false
      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The sheets never went away")
    }

    @MainActor
    func testEndingAQueuedSheetKeepsItFromAppearing() {
      let host = makeHost()
      let firstSheet = makeWindow()
      let secondSheet = makeWindow()
      @UIBinding var isFirstPresented = false
      @UIBinding var isSecondPresented = false
      host.window.sheet(isPresented: $isFirstPresented) { firstSheet }
      host.window.sheet(isPresented: $isSecondPresented) { secondSheet }

      isFirstPresented = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === firstSheet }, "The first sheet never appeared"
      )
      isSecondPresented = true
      spinRunLoop(for: 0.3)
      isSecondPresented = false
      spinRunLoop(for: 0.3)
      isFirstPresented = false
      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The first sheet never ended")
      spinRunLoop(for: 0.5)

      XCTAssertNil(host.window.attachedSheet, "The second sheet appeared after its binding ended it")
      XCTAssertFalse(secondSheet.isVisible, "The second sheet appeared after its binding ended it")
    }

    // MARK: - Alert content

    @MainActor
    func testClickingAButtonOfAnAlertSheetEndsTheSheetAndWritesFalseBack() throws {
      let host = makeHost()
      let alert = NSAlert()
      alert.messageText = "Delete the item?"
      alert.addButton(withTitle: "Delete")
      @UIBinding var isPresented = false
      host.window.sheet(isPresented: $isPresented) { alert }

      isPresented = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === alert.window },
        "The alert never appeared as a sheet"
      )
      let deleteButton = try XCTUnwrap(alert.buttons.first)
      deleteButton.performClick(nil)

      XCTAssertTrue(
        waitUntil { host.window.attachedSheet == nil && !isPresented },
        "Clicking the alert's button did not end the sheet"
      )
    }

    @MainActor
    func testAnAlertSheetShowsItsMessage() {
      let host = makeHost()
      let alert = NSAlert()
      alert.messageText = "Delete the item?"
      alert.informativeText = "This can't be undone."
      alert.addButton(withTitle: "Delete")
      @UIBinding var isPresented = false
      host.window.sheet(isPresented: $isPresented) { alert }

      isPresented = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === alert.window },
        "The alert never appeared as a sheet"
      )

      let shownTexts = Self.texts(in: alert.window.contentView)
      XCTAssertTrue(
        shownTexts.contains("Delete the item?") && shownTexts.contains("This can't be undone."),
        "The alert sheet does not show its texts: \(shownTexts)"
      )
    }

    @MainActor
    private static func texts(in view: NSView?) -> [String] {
      guard let view else { return [] }
      let ownText = (view as? NSTextField).map { [$0.stringValue] } ?? []
      return ownText + view.subviews.flatMap { texts(in: $0) }
    }

    // MARK: - Save panel content

    @MainActor
    func testCancellingASavePanelSheetEndsTheSheetAndWritesFalseBack() {
      let host = makeHost()
      let savePanel = NSSavePanel()
      @UIBinding var isPresented = false
      host.window.sheet(isPresented: $isPresented) { savePanel }

      isPresented = true
      XCTAssertTrue(
        waitUntil(timeout: 8) { host.window.attachedSheet === savePanel },
        "The save panel never appeared as a sheet"
      )
      // What the panel's Cancel button does.
      savePanel.cancel(nil)

      XCTAssertTrue(
        waitUntil(timeout: 5) { host.window.attachedSheet == nil && !isPresented },
        "Cancelling the panel did not end the sheet"
      )
    }
  }
#endif
