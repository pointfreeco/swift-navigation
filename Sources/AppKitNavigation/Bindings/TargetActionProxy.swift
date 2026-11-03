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
    //
    //     A 'nil' original target is forwarded as 'nil': it means "up the responder chain", which
    //     is where 'sendAction(_:to:from:)' routes it. Menu items, and controls wired to the
    //     first responder, rely on that.
    if !registersAsAdditionalTarget, let originAction {
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

/// AppKit enables a menu item or a toolbar item by asking its target. Once the proxy has taken the
/// item's target-action pair over, it is the one asked, so it answers the way the original pair
/// would have been answered.
extension TargetActionProxy: NSMenuItemValidation, NSToolbarItemValidation {
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    validateOriginalAction(for: menuItem) { receiver in
      receiver.validateMenuItem?(menuItem)
    }
  }

  func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
    validateOriginalAction(for: item) { receiver in
      receiver.validateToolbarItem?(item)
    }
  }

  private func validateOriginalAction(
    for item: any NSValidatedUserInterfaceItem,
    asking askReceiver: (AnyObject) -> Bool?
  ) -> Bool {
    // NB: An item that only runs closure actions has no one else to ask.
    guard let originAction else { return true }
    // NB: With no receiver for the original action, AppKit would have disabled the item.
    guard
      let receiver = NSApplication.shared.target(
        forAction: originAction, to: originTarget, from: item
      ) as AnyObject?
    else { return false }
    // NB: Looked up dynamically rather than through a protocol cast, since a receiver may
    //     implement these methods without declaring the protocols, as AppKit long allowed.
    if let answer = askReceiver(receiver) {
      return answer
    }
    return receiver.validateUserInterfaceItem?(item) ?? true
  }
}

#endif
