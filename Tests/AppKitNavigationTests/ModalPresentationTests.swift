#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import XCTest

  /// Windows presented through `modal(isModaled:)` and `modalSession(isModaled:)`.
  ///
  /// Synchronous XCTest methods on purpose: they wait by spinning the main run loop, which also
  /// services the modal loop that `modal` runs from a main-queue block.
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

    // MARK: - Modal loop

    @MainActor
    func testSettingTheBindingToFalseTakesTheModalWindowOffScreen() {
      let host = NSObject()
      let window = makeWindow()
      @UIBinding var isModaled = false
      host.modal(isModaled: $isModaled) { window }
      abortModalLoop(after: 5)

      // NB: 'modal' runs the modal loop from a main-queue block, so the loop is running by the
      //     time this fires, and it fires from inside it.
      let start = Date()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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

    // MARK: - Support

    @MainActor
    private func makeWindow() -> NSWindow {
      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 240, height: 160),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
      )
      window.isReleasedWhenClosed = false
      addTeardownBlock { @MainActor in
        window.close()
      }
      return window
    }

    /// Guards against a modal loop that never stops, which would otherwise hang the test run.
    @MainActor
    private func abortModalLoop(after timeout: TimeInterval) {
      let timer = Timer(timeInterval: timeout, repeats: false) { _ in
        MainActor.assumeIsolated {
          if NSApplication.shared.modalWindow != nil {
            NSApplication.shared.abortModal()
          }
        }
      }
      RunLoop.main.add(timer, forMode: .common)
      addTeardownBlock { @MainActor in
        timer.invalidate()
      }
    }

    @MainActor
    private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) -> Bool {
      let deadline = Date(timeIntervalSinceNow: timeout)
      while !condition(), Date() < deadline {
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
      }
      return condition()
    }
  }
#endif
