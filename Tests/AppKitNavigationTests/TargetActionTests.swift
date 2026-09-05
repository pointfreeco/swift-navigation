#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKitNavigation
  import XCTest

  final class TargetActionTests: XCTestCase {
    override func setUp() {
      super.setUp()
      // NB: 'performClick' routes through 'NSApplication.sendAction(_:to:from:)', which silently
      //     does nothing when no application object exists yet. XCTest runs 'setUp' on the main
      //     thread, so assuming main-actor isolation here is sound.
      MainActor.assumeIsolated {
        _ = NSApplication.shared
      }
    }

    private final class ActionRecipient: NSObject {
      nonisolated(unsafe) var callCount = 0

      @objc func recordAction(_ sender: Any?) {
        callCount += 1
      }
    }

    /// Whichever mechanism the proxy picks, a target-action pair installed *before* the first
    /// closure action has to keep firing, and exactly once.
    @MainActor
    func testExistingTargetActionKeepsFiringAlongsideClosureActions() {
      let recipient = ActionRecipient()
      let button = NSButton()
      button.target = recipient
      button.action = #selector(ActionRecipient.recordAction(_:))

      var closureCallCount = 0
      button.addAction { _ in closureCallCount += 1 }

      button.performClick(nil)

      XCTAssertEqual(recipient.callCount, 1)
      XCTAssertEqual(closureCallCount, 1)
    }

    @MainActor
    func testClosureActionFiresWithoutAnyTargetAction() {
      let button = NSButton()

      var closureCallCount = 0
      button.addAction { _ in closureCallCount += 1 }

      button.performClick(nil)
      button.performClick(nil)

      XCTAssertEqual(closureCallCount, 2)
    }

    @MainActor
    func testRemoveActionStopsTheClosure() {
      let button = NSButton()

      var closureCallCount = 0
      let id = button.addAction { _ in closureCallCount += 1 }
      button.removeAction(for: id)

      button.performClick(nil)

      XCTAssertEqual(closureCallCount, 0)
    }

    /// From macOS 27 on, AppKit delivers `primaryActionTriggered` / `valueChanged` to additional
    /// targets, so the proxy no longer has to seize the control's own pair. Below that it does,
    /// because only tracking events are sent and those do not stand for "the action fired".
    @MainActor
    func testProxyOnlySeizesTargetActionBelowMacOS27() {
      let recipient = ActionRecipient()
      let button = NSButton()
      button.target = recipient
      button.action = #selector(ActionRecipient.recordAction(_:))

      button.addAction { _ in }

      if #available(macOS 27, *) {
        XCTAssertIdentical(button.target as AnyObject?, recipient)
        XCTAssertEqual(button.action, #selector(ActionRecipient.recordAction(_:)))
      } else {
        XCTAssertNotIdentical(button.target as AnyObject?, recipient)
      }
    }

    /// A text field reports every keystroke through the notification on every OS version, which is
    /// why `valueChanged` is deliberately not registered for text fields.
    @MainActor
    func testTextFieldWritesBackOnEveryEdit() {
      @UIBinding var text = ""
      let textField = NSTextField(text: $text)

      textField.stringValue = "h"
      NotificationCenter.default.post(
        name: NSControl.textDidChangeNotification, object: textField
      )
      XCTAssertEqual(text, "h")

      textField.stringValue = "hi"
      NotificationCenter.default.post(
        name: NSControl.textDidChangeNotification, object: textField
      )
      XCTAssertEqual(text, "hi")
    }
  }
#endif
