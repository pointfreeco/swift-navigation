#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

class NestedModalViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyTitle = "Nested modals"
  let readMe = """
  A modal can present another modal on top of itself. Here a settings window runs modally, and \
  its Reset button asks for confirmation with an alert that runs on top of the window. Ending the \
  alert returns to the settings window, which is still running.

  The settings window can also be closed from its state while the alert is up — try "Close in 3 \
  seconds" and then "Reset…". AppKit only stops the innermost modal, so the window waits until \
  the alert has ended, and then closes.
  """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()

    let openButton = makeButton("Open the settings") { [weak self] in
      self?.model.isSettingsPresented = true
    }
    let statusLabel = NSTextField(wrappingLabelWithString: "")
    addColumn(of: [openButton, statusLabel], to: view)

    observe { [unowned self] in
      statusLabel.stringValue = """
        Settings window: \(model.isSettingsPresented ? "open" : "closed")
        Confirmation alert: \(model.resetConfirmation != nil ? "open" : "closed")
        Resets: \(model.resetCount)
        """
    }

    modal(isPresented: $model.isSettingsPresented) { [unowned self] in
      makeWindow(
        title: "Settings",
        message: "This window runs modally. Reset asks for confirmation with an alert on top of it.",
        buttons: [
          makeButton("Reset…") { [weak self] in
            self?.model.resetConfirmation = .reset
          },
          makeButton("Close in 3 seconds") { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
              self?.model.isSettingsPresented = false
            }
          },
          makeButton("Close") { [weak self] in
            self?.model.isSettingsPresented = false
          },
        ]
      )
    }

    modal(item: $model.resetConfirmation) { [unowned self] alert in
      NSAlert(state: alert) { [weak self] action in
        if action == .reset {
          self?.model.resetCount += 1
        }
      }
    }
  }

  @Observable
  class Model {
    var isSettingsPresented = false
    var resetConfirmation: AlertState<ConfirmationAction>?
    var resetCount = 0

    enum ConfirmationAction {
      case reset
    }
  }
}

extension AlertState where Action == NestedModalViewController.Model.ConfirmationAction {
  static var reset: Self {
    AlertState {
      TextState("Reset all settings?")
    } actions: {
      ButtonState(role: .destructive, action: .reset) {
        TextState("Reset")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    } message: {
      TextState("The settings go back to how they were when the app was installed.")
    }
  }
}

#Preview {
  NestedModalViewController()
}
#endif
