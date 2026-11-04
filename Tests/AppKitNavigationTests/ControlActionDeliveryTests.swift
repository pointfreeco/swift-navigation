#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  @MainActor
  @Suite struct ControlActionDeliveryTests {
    enum ControlKind: String, CaseIterable, Sendable {
      case pushButton
      case checkbox
      case radioButton
      case switchControl
      case stepper
      case segmentedControl
      case slider

      @MainActor func makeControl() -> NSControl {
        switch self {
        case .pushButton:
          NSButton(title: "Push", target: nil, action: nil)
        case .checkbox:
          NSButton(checkboxWithTitle: "Check", target: nil, action: nil)
        case .radioButton:
          NSButton(radioButtonWithTitle: "Radio", target: nil, action: nil)
        case .switchControl:
          NSSwitch()
        case .stepper:
          NSStepper()
        case .segmentedControl:
          NSSegmentedControl(labels: ["A", "B"], trackingMode: .selectOne, target: nil, action: nil)
        case .slider:
          NSSlider(value: 0.5, minValue: 0, maxValue: 1, target: nil, action: nil)
        }
      }
    }

    init() {
      // NB: 'performClick' routes through 'NSApplication.sendAction(_:to:from:)', which silently
      //     does nothing when no application object exists yet.
      _ = NSApplication.shared
    }

    /// On macOS 27 a click delivers `primaryActionTriggered` *and* `valueChanged` (a stepper even
    /// delivers `valueChanged` twice), so listening for both ran every closure several times.
    @Test("one click runs a closure action exactly once", arguments: ControlKind.allCases)
    func oneClickRunsClosureActionOnce(_ controlKind: ControlKind) {
      let control = controlKind.makeControl()
      var closureCallCount = 0
      control.addAction { _ in closureCallCount += 1 }

      control.performClick(nil)

      #expect(closureCallCount == 1)
    }

    /// Code that sends a control's action itself must reach closure actions too, as it did when
    /// the library owned the control's target-action pair.
    @Test(
      "sending the action programmatically runs a closure action exactly once",
      arguments: ControlKind.allCases
    )
    func sendingTheActionRunsClosureActionOnce(_ controlKind: ControlKind) {
      let actionRecipient = ActionRecipient()
      let control = controlKind.makeControl()
      control.target = actionRecipient
      control.action = #selector(ActionRecipient.receiveAction(_:))
      var closureCallCount = 0
      control.addAction { _ in closureCallCount += 1 }

      control.sendAction(control.action, to: control.target)

      #expect(closureCallCount == 1)
    }

    private final class ActionRecipient: NSObject {
      @objc func receiveAction(_ sender: Any?) {}
    }
  }
#endif
