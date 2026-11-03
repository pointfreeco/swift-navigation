#if canImport(AppKit) && !targetEnvironment(macCatalyst)

public import AppKit
public import IdentifiedCollections
import AppKitNavigationShim

@MainActor
class TargetActionProxy: NSObject {
  typealias ActionClosure = (Any?) -> Void

  typealias ActionIdentifier = UUID

  private struct Action: Identifiable {
    let id = UUID()

    var closure: ActionClosure

    func invoke(_ sender: Any?) {
      closure(sender)
    }
  }

  private var bindingActions: IdentifiedArrayOf<Action> = []

  private var actions: IdentifiedArrayOf<Action> = []

  private var originTarget: AnyObject?

  private var originAction: Selector?

  /// Whether this proxy registered itself as an *additional* target rather than taking over the
  /// control's single `target` / `action` pair.
  ///
  /// AppKit has stored several target-action pairs per control since macOS 11, but the event that
  /// stands for "the control's action fired" — `primaryActionTriggered` — is only delivered from
  /// macOS 27 on. Below that, only tracking events are sent, which is not the same thing (a
  /// keyboard-driven button never tracks), so the proxy still has to take the pair over.
  private let registersAsAdditionalTarget: Bool

  weak var owner: (any TargetActionProtocol)?

  required init(owner: any TargetActionProtocol) {
    self.owner = owner
    if #available(macOS 27, *) {
      registersAsAdditionalTarget = owner is NSControl
    } else {
      registersAsAdditionalTarget = false
    }
    super.init()

    if #available(macOS 27, *), registersAsAdditionalTarget, let control = owner as? NSControl {
      // NB: Only 'primaryActionTriggered' stands for "the control sent its action". Measured on
      //     macOS 27.2, every 'sendAction(_:to:)' delivers it exactly once, for every control type
      //     — buttons, switches, steppers, segmented controls, sliders, text fields, date pickers,
      //     color wells and path controls alike — which is what target-action delivered before.
      //     'valueChanged' is no substitute and must not be added alongside it: a click delivers
      //     it on top of 'primaryActionTriggered' (registering both ran every closure twice), a
      //     stepper click delivers it twice, and 'sendAction(_:to:)' does not deliver it at all.
      //
      //     A text field's per-keystroke changes arrive through the notification below on every
      //     OS version, so text fields need nothing more.
      //
      //     The event set is spelled as a literal on purpose: the option set is named
      //     'NSControlEvents' when it comes from the shim and 'NSControl.Events' when it comes
      //     from the macOS 27 SDK, and inference makes both spellings compile.
      control.addTarget(self, action: #selector(invokeAction(_:)), for: [.primaryActionTriggered])
    } else {
      self.originTarget = owner.target
      self.originAction = owner.action
      owner.target = self
      owner.action = #selector(invokeAction(_:))
    }

    if let textField = owner as? NSTextField {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(controlTextDidChange(_:)),
        name: NSControl.textDidChangeNotification,
        object: textField
      )
    }
  }

  @objc func controlTextDidChange(_ obj: Notification) {
    bindingActions.forEach { $0.invoke(obj.object) }
    actions.forEach { $0.invoke(obj.object) }
  }

  @objc func invokeAction(_ sender: Any?) {
    // NB: When registered as an additional target the original pair is still installed on the
    //     control, so AppKit delivers to it directly and forwarding here would double up.
    if !registersAsAdditionalTarget, let originTarget, let originAction {
      NSApplication.shared.sendAction(originAction, to: originTarget, from: sender)
    }
    bindingActions.forEach { $0.invoke(sender) }
    actions.forEach { $0.invoke(sender) }
  }

  @discardableResult
  func addAction(_ actionClosure: @escaping ActionClosure) -> ActionIdentifier {
    let action = Action(closure: actionClosure)
    actions.append(action)
    return action.id
  }

  func removeAction(for id: ActionIdentifier) {
    actions.remove(id: id)
  }

  func removeAllActions() {
    actions.removeAll()
  }

  @discardableResult
  func addBindingAction(_ bindingActionClosure: @escaping ActionClosure) -> ActionIdentifier {
    let bindingAction = Action(closure: bindingActionClosure)
    bindingActions.append(bindingAction)
    return bindingAction.id
  }

  func removeBindingAction(for id: ActionIdentifier) {
    bindingActions.remove(id: id)
  }

  func removeAllBindingActions() {
    bindingActions.removeAll()
  }
}

#endif
