#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// Content presented through `modal(isModaled:)` and `modalSession(isModaled:)`.
  final class ModalPresentationTests: XCTestCase {
    override func setUp() {
      super.setUp()
      MainActor.assumeIsolated {
        _ = NSApplication.shared
      }
    }

    // MARK: - Modal session

    @MainActor
    func testUserClosingAModalSessionWindowWritesFalseBack() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isModaled = false
      host.modalSession(isModaled: $isModaled) { window }

      isModaled = true
      XCTAssertTrue(waitUntil { window.isVisible }, "The window never appeared")

      // What the window's close button does once 'windowShouldClose' agrees.
      window.close()

      XCTAssertTrue(waitUntil { !isModaled }, "Closing the window did not write 'false' back")
    }

    @MainActor
    func testSettingTheBindingToFalseEndsTheModalSession() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isModaled = false
      host.modalSession(isModaled: $isModaled) { window }

      isModaled = true
      XCTAssertTrue(
        waitUntil { NSApplication.shared.modalWindow === window }, "The modal session never began"
      )

      isModaled = false

      XCTAssertTrue(
        waitUntil { NSApplication.shared.modalWindow == nil && !window.isVisible },
        "The modal session did not end, or its window stayed on screen"
      )
    }

    @MainActor
    func testStartingAModalSessionLeavesAnotherBindingsSessionInPlace() {
      let host = NSObject()
      let firstWindow = makeWindow()
      let secondWindow = makeWindow()
      @UIBinding var isFirstModaled = false
      @UIBinding var isSecondModaled = false
      var secondDismissCount = 0
      host.modalSession(isModaled: $isFirstModaled) { firstWindow }
      host.modalSession(isModaled: $isSecondModaled, onDismiss: { secondDismissCount += 1 }) {
        secondWindow
      }

      isFirstModaled = true
      XCTAssertTrue(
        waitUntil { NSApplication.shared.modalWindow === firstWindow },
        "The first modal session never began"
      )
      isSecondModaled = true
      XCTAssertTrue(
        waitUntil { NSApplication.shared.modalWindow === secondWindow },
        "The second modal session never began"
      )
      spinRunLoop(for: 0.3)

      XCTExpectFailure("Starting a modal session closes whatever session window the library runs") {
        XCTAssertTrue(isFirstModaled, "Starting the second session ended the first binding's session")
        XCTAssertTrue(firstWindow.isVisible, "Starting the second session closed the first window")
        XCTAssertEqual(
          secondDismissCount, 0,
          "The second binding's 'onDismiss' ran for a session it never started"
        )
      }

      isSecondModaled = false
      isFirstModaled = false
      XCTAssertTrue(
        waitUntil { NSApplication.shared.modalWindow == nil }, "The modal sessions never ended"
      )
    }

    // MARK: - Modal loop

    @MainActor
    func testSettingTheBindingToFalseTakesTheModalWindowOffScreen() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isModaled = false
      host.modal(isModaled: $isModaled) { window }
      abortModalLoops(after: 5)

      let start = Date()
      perform(after: 0.5) {
        isModaled = false
      }
      isModaled = true

      XCTAssertTrue(waitUntil(timeout: 4) { !isModaled }, "The binding was never reset")
      XCTAssertLessThan(
        Date().timeIntervalSince(start), 3,
        """
        The modal loop only ended when the safety timer aborted it: setting the binding to 'false' \
        could not stop it
        """
      )
      XCTAssertTrue(
        waitUntil { !window.isVisible }, "The window stayed on screen after the modal loop ended"
      )
    }

    @MainActor
    func testUserClosingAModalWindowWritesFalseBack() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isModaled = false
      host.modal(isModaled: $isModaled) { window }
      abortModalLoops(after: 5)

      let start = Date()
      perform(after: 0.5) {
        // What the window's close button does once 'windowShouldClose' agrees.
        window.close()
      }
      isModaled = true

      XCTAssertTrue(waitUntil(timeout: 4) { !isModaled }, "Closing the window did not write 'false' back")
      XCTAssertLessThan(
        Date().timeIntervalSince(start), 3,
        "The modal loop only ended when the safety timer aborted it: closing the window did not stop it"
      )
    }

    @MainActor
    func testSettingTheBindingToFalseCallsOnDismissOnce() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isModaled = false
      var dismissCount = 0
      host.modal(isModaled: $isModaled, onDismiss: { dismissCount += 1 }) { window }
      abortModalLoops(after: 5)

      perform(after: 0.5) {
        isModaled = false
      }
      isModaled = true

      XCTAssertTrue(waitUntil(timeout: 4) { !isModaled }, "The binding was never reset")
      spinRunLoop(for: 0.3)
      XCTAssertEqual(dismissCount, 1)
    }

    @MainActor
    func testSettingTheBindingToFalseStopsAModalAlert() {
      let host = NSObject()
      let alert = NSAlert()
      alert.messageText = "Discard the changes?"
      alert.addButton(withTitle: "Discard")
      @UIBinding var isModaled = false
      host.modal(isModaled: $isModaled) { alert }
      abortModalLoops(after: 5)

      let start = Date()
      perform(after: 0.5) {
        isModaled = false
      }
      isModaled = true

      XCTAssertTrue(waitUntil(timeout: 4) { !isModaled }, "The binding was never reset")
      XCTAssertLessThan(
        Date().timeIntervalSince(start), 3,
        "The alert only ended when the safety timer aborted it: setting the binding to 'false' could not stop it"
      )
      XCTAssertTrue(waitUntil { !alert.window.isVisible }, "The alert stayed on screen")
    }

    @MainActor
    func testSettingTheBindingToFalseStopsAModalSavePanel() {
      let host = NSObject()
      let savePanel = NSSavePanel()
      @UIBinding var isModaled = false
      host.modal(isModaled: $isModaled) { savePanel }
      abortModalLoops(after: 8)

      let start = Date()
      perform(after: 1) {
        isModaled = false
      }
      isModaled = true

      XCTAssertTrue(waitUntil(timeout: 7) { !isModaled }, "The binding was never reset")
      XCTAssertLessThan(
        Date().timeIntervalSince(start), 6,
        "The panel only ended when the safety timer aborted it: setting the binding to 'false' could not stop it"
      )
    }

    @MainActor
    func testModalPresentedFromAModalStaysOnTopOfIt() {
      let host = NSObject()
      let window = makeWindow()
      let alert = NSAlert()
      alert.messageText = "Discard the changes?"
      alert.addButton(withTitle: "Discard")
      @UIBinding var isWindowModaled = false
      @UIBinding var isAlertModaled = false
      host.modal(isModaled: $isWindowModaled) { window }
      host.modal(isModaled: $isAlertModaled) { alert }
      abortModalLoops(after: 6)

      let windowStayedModaled = Recorded(false)
      let windowStayedVisible = Recorded(false)
      let alertWasOnTop = Recorded(false)
      perform(after: 0.4) {
        isAlertModaled = true
      }
      perform(after: 1.2) {
        windowStayedModaled.value = isWindowModaled
        windowStayedVisible.value = window.isVisible
        alertWasOnTop.value = NSApplication.shared.modalWindow === alert.window
        isAlertModaled = false
      }
      perform(after: 1.8) {
        isWindowModaled = false
      }
      isWindowModaled = true

      XCTAssertTrue(
        waitUntil(timeout: 5) {
          !isWindowModaled && !isAlertModaled && NSApplication.shared.modalWindow == nil
        },
        "The modals never all ended"
      )
      XCTExpectFailure(
        """
        Presenting a modal stops whatever modal loop is running, and only starts its own loop in the \
        default run loop mode
        """
      ) {
        XCTAssertTrue(windowStayedModaled.value, "Presenting the alert ended the window's modal")
        XCTAssertTrue(windowStayedVisible.value, "Presenting the alert took the window off screen")
        XCTAssertTrue(alertWasOnTop.value, "The alert did not run on top of the window")
      }
    }

    @MainActor
    func testAWindowIsReleasedOnceItsModalEnds() {
      let host = NSObject()
      weak var presentedWindow: NSWindow?
      @UIBinding var isModaled = false
      host.modal(isModaled: $isModaled) {
        let window = NSWindow(
          contentRect: NSRect(x: 0, y: 0, width: 240, height: 160),
          styleMask: [.titled, .closable],
          backing: .buffered,
          defer: false
        )
        window.isReleasedWhenClosed = false
        presentedWindow = window
        return window
      }
      abortModalLoops(after: 5)

      perform(after: 0.5) {
        isModaled = false
      }
      isModaled = true

      XCTAssertTrue(waitUntil(timeout: 4) { !isModaled }, "The binding was never reset")
      spinRunLoop(for: 0.3)
      XCTExpectFailure("A process-wide table keeps every modal window that is not closed") {
        XCTAssertNil(presentedWindow, "The window is still held after its modal ended")
      }
    }
  }
#endif
