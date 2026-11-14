#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// Content presented through `modal(isPresented:)` and `modalSession(isPresented:)`, and the
  /// lifecycle every presentation shares, tried out on modals.
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
      @UIBinding var isPresented = false
      host.modalSession(isPresented: $isPresented) { window }

      isPresented = true
      XCTAssertTrue(waitUntil { window.isVisible }, "The window never appeared")

      // What the window's close button does once 'windowShouldClose' agrees.
      window.close()

      XCTAssertTrue(waitUntil { !isPresented }, "Closing the window did not write 'false' back")
    }

    @MainActor
    func testSettingTheBindingToFalseEndsTheModalSession() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isPresented = false
      host.modalSession(isPresented: $isPresented) { window }

      isPresented = true
      XCTAssertTrue(
        waitUntil { NSApplication.shared.modalWindow === window }, "The modal session never began"
      )

      isPresented = false

      XCTAssertTrue(
        waitUntil { NSApplication.shared.modalWindow == nil && !window.isVisible },
        "The modal session did not end, or its window stayed on screen"
      )
    }

    @MainActor
    func testOnDismissRunsOnceTheSessionWindowHasLeftTheScreen() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isPresented = false
      var windowWasVisibleAtDismiss: Bool?
      host.modalSession(
        isPresented: $isPresented,
        onDismiss: { windowWasVisibleAtDismiss = window.isVisible }
      ) {
        window
      }

      isPresented = true
      XCTAssertTrue(waitUntil { window.isVisible }, "The window never appeared")
      window.close()
      XCTAssertTrue(waitUntil { windowWasVisibleAtDismiss != nil }, "'onDismiss' never ran")

      XCTAssertEqual(
        windowWasVisibleAtDismiss, false, "'onDismiss' ran while the window was on screen"
      )
    }

    @MainActor
    func testStartingAModalSessionLeavesAnotherBindingsSessionInPlace() {
      let host = NSObject()
      let firstWindow = makeWindow()
      let secondWindow = makeWindow()
      @UIBinding var isFirstPresented = false
      @UIBinding var isSecondPresented = false
      var secondDismissCount = 0
      host.modalSession(isPresented: $isFirstPresented) { firstWindow }
      host.modalSession(isPresented: $isSecondPresented, onDismiss: { secondDismissCount += 1 }) {
        secondWindow
      }

      isFirstPresented = true
      XCTAssertTrue(
        waitUntil { NSApplication.shared.modalWindow === firstWindow },
        "The first modal session never began"
      )
      isSecondPresented = true
      XCTAssertTrue(
        waitUntil { NSApplication.shared.modalWindow === secondWindow },
        "The second modal session never began"
      )
      spinRunLoop(for: 0.3)

      XCTAssertTrue(isFirstPresented, "Starting the second session ended the first binding's session")
      XCTAssertTrue(firstWindow.isVisible, "Starting the second session closed the first window")
      XCTAssertEqual(
        secondDismissCount, 0, "The second binding's 'onDismiss' ran for a session it never started"
      )

      isSecondPresented = false
      isFirstPresented = false
      XCTAssertTrue(
        waitUntil { NSApplication.shared.modalWindow == nil }, "The modal sessions never ended"
      )
    }

    // MARK: - Modal loop

    @MainActor
    func testSettingTheBindingToFalseTakesTheModalWindowOffScreen() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isPresented = false
      host.modal(isPresented: $isPresented) { window }
      abortModalLoops(after: 5)

      let start = Date()
      perform(after: 0.5) {
        isPresented = false
      }
      isPresented = true

      XCTAssertTrue(waitUntil(timeout: 4) { !isPresented }, "The binding was never reset")
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
      @UIBinding var isPresented = false
      host.modal(isPresented: $isPresented) { window }
      abortModalLoops(after: 5)

      let start = Date()
      perform(after: 0.5) {
        // What the window's close button does once 'windowShouldClose' agrees.
        window.close()
      }
      isPresented = true

      XCTAssertTrue(
        waitUntil(timeout: 4) { !isPresented }, "Closing the window did not write 'false' back"
      )
      XCTAssertLessThan(
        Date().timeIntervalSince(start), 3,
        "The modal loop only ended when the safety timer aborted it: closing the window did not stop it"
      )
    }

    @MainActor
    func testSettingTheBindingToFalseCallsOnDismissOnce() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isPresented = false
      var dismissCount = 0
      host.modal(isPresented: $isPresented, onDismiss: { dismissCount += 1 }) { window }
      abortModalLoops(after: 5)

      perform(after: 0.5) {
        isPresented = false
      }
      isPresented = true

      XCTAssertTrue(waitUntil(timeout: 4) { !isPresented }, "The binding was never reset")
      spinRunLoop(for: 0.3)
      XCTAssertEqual(dismissCount, 1)
    }

    @MainActor
    func testUserEndingAModalAlertCallsOnDismissOnce() {
      let host = NSObject()
      let presentedAlert = WeakReference<NSAlert>()
      @UIBinding var isPresented = false
      let dismissCount = Recorded(0)
      host.modal(isPresented: $isPresented, onDismiss: { dismissCount.value += 1 }) {
        // NB: Made here, and held by nothing but the presentation.
        let alert = NSAlert()
        alert.messageText = "Discard the changes?"
        alert.addButton(withTitle: "Discard")
        presentedAlert.object = alert
        return alert
      }
      abortModalLoops(after: 5)

      perform(after: 0.5) {
        presentedAlert.object?.buttons.first?.performClick(nil)
      }
      isPresented = true

      XCTAssertTrue(
        waitUntil(timeout: 4) { !isPresented }, "Clicking the alert's button did not write 'false' back"
      )
      spinRunLoop(for: 0.3)
      XCTAssertEqual(dismissCount.value, 1, "'onDismiss' did not run once the user ended the alert")
    }

    @MainActor
    func testSettingTheBindingToFalseStopsAModalAlert() {
      let host = NSObject()
      let alert = NSAlert()
      alert.messageText = "Discard the changes?"
      alert.addButton(withTitle: "Discard")
      @UIBinding var isPresented = false
      host.modal(isPresented: $isPresented) { alert }
      abortModalLoops(after: 5)

      let start = Date()
      perform(after: 0.5) {
        isPresented = false
      }
      isPresented = true

      XCTAssertTrue(waitUntil(timeout: 4) { !isPresented }, "The binding was never reset")
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
      @UIBinding var isPresented = false
      host.modal(isPresented: $isPresented) { savePanel }
      abortModalLoops(after: 8)

      let start = Date()
      perform(after: 1) {
        isPresented = false
      }
      isPresented = true

      XCTAssertTrue(waitUntil(timeout: 7) { !isPresented }, "The binding was never reset")
      XCTAssertLessThan(
        Date().timeIntervalSince(start), 6,
        "The panel only ended when the safety timer aborted it: setting the binding to 'false' could not stop it"
      )
    }

    @MainActor
    func testChangingTheItemEndsTheModalBeforeTheNextOneRuns() {
      struct Item: Identifiable {
        let id: Int
      }
      let host = NSObject()
      let firstWindow = makeWindow()
      let secondWindow = makeWindow()
      @UIBinding var item: Item?
      let dismissCount = Recorded(0)
      host.modal(item: $item, onDismiss: { dismissCount.value += 1 }) { currentItem in
        currentItem.id == 1 ? firstWindow : secondWindow
      }
      abortModalLoops(after: 6)

      let firstWasGoneWhenSecondRan = Recorded(false)
      let dismissCountWhenSecondRan = Recorded(-1)
      perform(after: 0.5) {
        item = Item(id: 2)
      }
      perform(after: 1.2) {
        firstWasGoneWhenSecondRan.value =
          !firstWindow.isVisible && NSApplication.shared.modalWindow === secondWindow
        dismissCountWhenSecondRan.value = dismissCount.value
        item = nil
      }
      item = Item(id: 1)

      XCTAssertTrue(
        waitUntil(timeout: 5) { item == nil && NSApplication.shared.modalWindow == nil },
        "The modals never ended"
      )
      XCTAssertTrue(
        firstWasGoneWhenSecondRan.value,
        "The second item's modal did not run in place of the first item's"
      )
      XCTAssertEqual(
        dismissCountWhenSecondRan.value, 1,
        "'onDismiss' did not run exactly once for the first item before the second item's modal ran"
      )
      spinRunLoop(for: 0.3)
      XCTAssertEqual(dismissCount.value, 2)
    }

    @MainActor
    func testModalPresentedFromAModalStaysOnTopOfIt() {
      let host = NSObject()
      let window = makeWindow()
      let alert = NSAlert()
      alert.messageText = "Discard the changes?"
      alert.addButton(withTitle: "Discard")
      @UIBinding var isWindowPresented = false
      @UIBinding var isAlertPresented = false
      host.modal(isPresented: $isWindowPresented) { window }
      host.modal(isPresented: $isAlertPresented) { alert }
      abortModalLoops(after: 6)

      let windowStayedPresented = Recorded(false)
      let windowStayedVisible = Recorded(false)
      let alertWasOnTop = Recorded(false)
      perform(after: 0.4) {
        isAlertPresented = true
      }
      perform(after: 1.2) {
        windowStayedPresented.value = isWindowPresented
        windowStayedVisible.value = window.isVisible
        alertWasOnTop.value = NSApplication.shared.modalWindow === alert.window
        isAlertPresented = false
      }
      perform(after: 1.8) {
        isWindowPresented = false
      }
      isWindowPresented = true

      XCTAssertTrue(
        waitUntil(timeout: 5) {
          !isWindowPresented && !isAlertPresented && NSApplication.shared.modalWindow == nil
        },
        "The modals never all ended"
      )
      XCTAssertTrue(windowStayedPresented.value, "Presenting the alert ended the window's modal")
      XCTAssertTrue(windowStayedVisible.value, "Presenting the alert took the window off screen")
      XCTAssertTrue(alertWasOnTop.value, "The alert did not run on top of the window")
    }

    @MainActor
    func testEndingAModalCoveredByAnotherWaitsUntilItIsOnTop() {
      let host = NSObject()
      let window = makeWindow()
      let alert = NSAlert()
      alert.messageText = "Discard the changes?"
      alert.addButton(withTitle: "Discard")
      @UIBinding var isWindowPresented = false
      @UIBinding var isAlertPresented = false
      host.modal(isPresented: $isWindowPresented) { window }
      host.modal(isPresented: $isAlertPresented) { alert }
      abortModalLoops(after: 6)

      let alertStayedOnTop = Recorded(false)
      let windowStayedUnderIt = Recorded(false)
      let isFinished = Recorded(false)
      perform(after: 0.4) {
        isAlertPresented = true
      }
      perform(after: 1.0) {
        isWindowPresented = false
      }
      perform(after: 1.5) {
        alertStayedOnTop.value = NSApplication.shared.modalWindow === alert.window
        windowStayedUnderIt.value = window.isVisible
        isAlertPresented = false
        isFinished.value = true
      }
      isWindowPresented = true

      XCTAssertTrue(
        waitUntil(timeout: 5) {
          isFinished.value && NSApplication.shared.modalWindow == nil && !window.isVisible
        },
        "The window's modal never ended once the alert on top of it had"
      )
      XCTAssertTrue(alertStayedOnTop.value, "Ending the window's modal ended the alert on top of it")
      XCTAssertTrue(
        windowStayedUnderIt.value, "The window left the screen while the alert was still on top of it"
      )
    }

    @MainActor
    func testEndingOneModalAndPresentingAnotherInTheSameTurnRunsTheNewOne() {
      let host = NSObject()
      let window = makeWindow()
      let alert = NSAlert()
      alert.messageText = "Discard the changes?"
      alert.addButton(withTitle: "Discard")
      @UIBinding var isWindowPresented = false
      @UIBinding var isAlertPresented = false
      host.modal(isPresented: $isWindowPresented) { window }
      host.modal(isPresented: $isAlertPresented) { alert }
      abortModalLoops(after: 6)

      let alertRan = Recorded(false)
      let windowEnded = Recorded(false)
      perform(after: 0.5) {
        isWindowPresented = false
        isAlertPresented = true
      }
      perform(after: 1.2) {
        alertRan.value = NSApplication.shared.modalWindow === alert.window
        windowEnded.value = !window.isVisible
        isAlertPresented = false
      }
      isWindowPresented = true

      XCTAssertTrue(
        waitUntil(timeout: 5) {
          NSApplication.shared.modalWindow == nil && !isWindowPresented && !isAlertPresented
        },
        "The modals never all ended"
      )
      XCTAssertTrue(alertRan.value, "The alert did not run")
      XCTAssertTrue(windowEnded.value, "The window's modal did not end")
    }

    @MainActor
    func testAWindowIsReleasedOnceItsModalEnds() {
      let host = NSObject()
      weak var presentedWindow: NSWindow?
      @UIBinding var isPresented = false
      host.modal(isPresented: $isPresented) {
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
        isPresented = false
      }
      isPresented = true

      XCTAssertTrue(waitUntil(timeout: 4) { !isPresented }, "The binding was never reset")
      spinRunLoop(for: 0.3)
      XCTAssertNil(presentedWindow, "The window is still held after its modal ended")
    }

    // MARK: - Owner and token

    @MainActor
    func testReleasingTheOwnerEndsItsModal() {
      let owner = Recorded<NSObject?>(NSObject())
      let window = makeWindow()
      @UIBinding var isPresented = false
      let dismissCount = Recorded(0)
      owner.value?.modal(isPresented: $isPresented, onDismiss: { dismissCount.value += 1 }) {
        window
      }
      abortModalLoops(after: 5)

      let start = Date()
      perform(after: 0.5) {
        owner.value = nil
      }
      isPresented = true

      XCTAssertTrue(
        waitUntil(timeout: 4) { !isPresented }, "Releasing the owner did not end its modal"
      )
      XCTAssertLessThan(
        Date().timeIntervalSince(start), 3,
        "The modal loop only ended when the safety timer aborted it: releasing the owner did not stop it"
      )
      XCTAssertTrue(waitUntil { !window.isVisible }, "The window stayed on screen")
      spinRunLoop(for: 0.3)
      XCTAssertEqual(dismissCount.value, 1)
    }

    @MainActor
    func testCancellingTheTokenStopsFollowingTheBinding() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isPresented = false
      let token = host.modal(isPresented: $isPresented) { window }
      abortModalLoops(after: 5)

      let windowStayedModal = Recorded(false)
      let isFinished = Recorded(false)
      perform(after: 0.5) {
        token.cancel()
        isPresented = false
      }
      perform(after: 1) {
        windowStayedModal.value = NSApplication.shared.modalWindow === window
        window.close()
        isFinished.value = true
      }
      isPresented = true

      XCTAssertTrue(
        waitUntil(timeout: 4) { isFinished.value && NSApplication.shared.modalWindow == nil },
        "The modal never ended"
      )
      XCTAssertTrue(
        windowStayedModal.value,
        "Setting the binding to 'false' still ended the modal after the token was cancelled"
      )
    }

    @MainActor
    func testUserEndingContentAfterTheTokenIsCancelledStillWritesBack() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isPresented = false
      let dismissCount = Recorded(0)
      let token = host.modal(isPresented: $isPresented, onDismiss: { dismissCount.value += 1 }) {
        window
      }
      abortModalLoops(after: 5)

      perform(after: 0.5) {
        token.cancel()
      }
      perform(after: 0.8) {
        window.close()
      }
      isPresented = true

      XCTAssertTrue(
        waitUntil(timeout: 4) { !isPresented },
        "Closing the window after the token was cancelled did not write 'false' back"
      )
      spinRunLoop(for: 0.3)
      XCTAssertEqual(dismissCount.value, 1)
    }
  }
#endif
