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
      @UIBinding var isSheeted = false
      host.window.sheet(isSheeted: $isSheeted) { sheetWindow }

      isSheeted = true

      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === sheetWindow }, "The sheet never appeared"
      )
    }

    @MainActor
    func testSettingTheBindingToFalseEndsTheSheet() {
      let host = makeHost()
      let sheetWindow = makeWindow()
      @UIBinding var isSheeted = false
      host.window.sheet(isSheeted: $isSheeted) { sheetWindow }

      isSheeted = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === sheetWindow }, "The sheet never appeared"
      )

      isSheeted = false

      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The sheet was not ended")
    }

    @MainActor
    func testUserEndingTheSheetWritesFalseBack() {
      let host = makeHost()
      let sheetWindow = makeWindow()
      @UIBinding var isSheeted = false
      host.window.sheet(isSheeted: $isSheeted) { sheetWindow }

      isSheeted = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === sheetWindow }, "The sheet never appeared"
      )

      // What a Cancel button in the sheet does.
      host.window.endSheet(sheetWindow)

      XCTAssertTrue(waitUntil { !isSheeted }, "Ending the sheet did not write 'false' back")
    }

    @MainActor
    func testSettingTheBindingToFalseCallsOnDismissOnce() {
      let host = makeHost()
      let sheetWindow = makeWindow()
      @UIBinding var isSheeted = false
      var dismissCount = 0
      host.window.sheet(isSheeted: $isSheeted, onDismiss: { dismissCount += 1 }) { sheetWindow }

      isSheeted = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === sheetWindow }, "The sheet never appeared"
      )
      isSheeted = false
      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The sheet was not ended")
      spinRunLoop(for: 0.3)

      XCTAssertEqual(dismissCount, 1)
    }

    @MainActor
    func testPresentingASheetLeavesAnotherBindingsSheetInPlace() {
      let host = makeHost()
      let firstSheet = makeWindow()
      let secondSheet = makeWindow()
      @UIBinding var isFirstSheeted = false
      @UIBinding var isSecondSheeted = false
      var secondDismissCount = 0
      host.window.sheet(isSheeted: $isFirstSheeted) { firstSheet }
      host.window.sheet(isSheeted: $isSecondSheeted, onDismiss: { secondDismissCount += 1 }) {
        secondSheet
      }

      isFirstSheeted = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === firstSheet }, "The first sheet never appeared"
      )
      isSecondSheeted = true
      spinRunLoop(for: 0.5)

      XCTExpectFailure(
        "A new sheet ends whatever sheet the window has, and calls its own onDismiss for it"
      ) {
        XCTAssertTrue(isFirstSheeted, "Presenting the second sheet ended the first binding's sheet")
        XCTAssertEqual(
          secondDismissCount, 0,
          "The second binding's 'onDismiss' ran for a sheet it never presented"
        )
      }

      isFirstSheeted = false
      isSecondSheeted = false
      XCTAssertTrue(waitUntil { host.window.attachedSheet == nil }, "The sheets never went away")
    }

    // MARK: - Alert content

    @MainActor
    func testClickingAButtonOfAnAlertSheetEndsTheSheetAndWritesFalseBack() throws {
      let host = makeHost()
      let alert = NSAlert()
      alert.messageText = "Delete the item?"
      alert.addButton(withTitle: "Delete")
      @UIBinding var isSheeted = false
      host.window.sheet(isSheeted: $isSheeted) { alert }

      isSheeted = true
      XCTAssertTrue(
        waitUntil { host.window.attachedSheet === alert.window },
        "The alert never appeared as a sheet"
      )
      let deleteButton = try XCTUnwrap(alert.buttons.first)
      deleteButton.performClick(nil)

      XCTAssertTrue(
        waitUntil { host.window.attachedSheet == nil && !isSheeted },
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
      @UIBinding var isSheeted = false
      host.window.sheet(isSheeted: $isSheeted) { alert }

      isSheeted = true
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
      @UIBinding var isSheeted = false
      host.window.sheet(isSheeted: $isSheeted) { savePanel }

      isSheeted = true
      XCTAssertTrue(
        waitUntil(timeout: 8) { host.window.attachedSheet === savePanel },
        "The save panel never appeared as a sheet"
      )
      // What the panel's Cancel button does.
      savePanel.cancel(nil)

      XCTExpectFailure(
        "A save panel is attached with NSWindow.beginSheet(_:) instead of its own beginSheetModal(for:)"
      ) {
        XCTAssertTrue(
          waitUntil(timeout: 5) { host.window.attachedSheet == nil && !isSheeted },
          "Cancelling the panel did not end the sheet"
        )
      }
    }
  }
#endif
