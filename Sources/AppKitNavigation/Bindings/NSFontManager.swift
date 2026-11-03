#if canImport(AppKit) && !targetEnvironment(macCatalyst)

@_spi(Internals) public import SwiftNavigation
public import AppKit
public import IdentifiedCollections

extension NSFontManager: @unchecked @retroactive Sendable {}

@MainActor
extension NSFontManager {
  /// Returns the shared font manager, with the binding registered against its selected font.
  ///
  /// `NSFontManager()` returns the shared font manager, so this binds the same instance as
  /// `NSFontManager.shared.bind(font:)`.
  ///
  /// - Parameter font: The binding to read from for the selected font, and write to when a
  ///   change from the font panel or the font menu is applied.
  public convenience init(font: UIBinding<NSFont>) {
    self.init()
    bind(font: font)
  }

  /// Establishes a two-way connection between a binding and the font manager's selected font.
  ///
  /// The binding's font becomes the selected font that the font panel shows. When the user changes
  /// it from the font panel or the font menu, the change is applied to the binding's font, the way
  /// a text view applies it to its own.
  ///
  /// > Important: The font manager only sends font changes while some responder in the chain
  /// > implements `changeFont(_:)` — usually the text view being edited. While none does, changes
  /// > from the font panel do not reach the binding either.
  ///
  /// - Parameter font: The binding to read from for the selected font, and write to when a
  ///   change from the font panel or the font menu is applied.
  /// - Returns: A cancel token.
  @discardableResult
  public func bind(font: UIBinding<NSFont>) -> ObserveToken {
    bind(font, to: \._selectedFont)
  }

  @objc private var _selectedFont: NSFont {
    set { setSelectedFont(newValue, isMultiple: false) }
    // NB: 'convert(_:)' applies the font panel's latest change to the font it is given. That has
    //     to be the bound font, which the setter above recorded as the selected font; converting
    //     anything else keeps only the change and loses the bound font's family and size.
    get { convert(selectedFont ?? .systemFont(ofSize: 0)) }
  }
}

@MainActor
extension NSFontManager {
  /// Establishes a two-way connection between a source of truth and a property of this control.
  ///
  /// - Parameters:
  ///   - binding: A source of truth for the control's value.
  ///   - keyPath: A key path to the control's value.
  ///   - event: The control-specific events for which the binding is updated.
  /// - Returns: A cancel token.
  @discardableResult
  public func bind<Value>(
    _ binding: UIBinding<Value>,
    to keyPath: ReferenceWritableKeyPath<NSFontManager, Value>
  ) -> ObserveToken {
    bind(binding, to: keyPath) { control, newValue, _ in
      control[keyPath: keyPath] = newValue
    }
  }

  private var actionProxy: FontManagerProxy? {
    set {
      objc_setAssociatedObject(self, actionProxyKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    get {
      objc_getAssociatedObject(self, actionProxyKey) as? FontManagerProxy
    }
  }

  private func createActionProxyIfNeeded() -> FontManagerProxy {
    if let actionProxy {
      return actionProxy
    } else {
      let actionProxy = FontManagerProxy(owner: self)
      self.actionProxy = actionProxy
      return actionProxy
    }
  }

  /// Establishes a two-way connection between a source of truth and a property of this control.
  ///
  /// - Parameters:
  ///   - binding: A source of truth for the control's value.
  ///   - keyPath: A key path to the control's value.
  ///   - event: The control-specific events for which the binding is updated.
  ///   - set: A closure that is called when the binding's value changes with a weakly-captured
  ///     control, a new value that can be used to configure the control, and a transaction, which
  ///     can be used to determine how and if the change should be animated.
  /// - Returns: A cancel token.
  @discardableResult
  public func bind<Value>(
    _ binding: UIBinding<Value>,
    to keyPath: KeyPath<NSFontManager, Value>,
    set: @escaping (_ control: NSFontManager, _ newValue: Value, _ transaction: UITransaction) -> Void
  ) -> ObserveToken {
    unbind(keyPath)
    let actionProxy = createActionProxyIfNeeded()
    let actionID = actionProxy.addBindingAction { [weak self] _ in
      guard let self else { return }
      binding.wrappedValue = self[keyPath: keyPath]
    }

    let isSetting = LockIsolated(false)
    let token = observe { [weak self] transaction in
      guard let self else { return }
      isSetting.withLock { $0 = true }
      defer { isSetting.withLock { $0 = false } }
      set(
        self,
        binding.wrappedValue,
        transaction.appKit.animation == nil && !transaction.appKit.disablesAnimations
          ? binding.transaction
          : transaction
      )
    }
    // NB: This key path must only be accessed on the main actor
    nonisolated(unsafe) let uncheckedKeyPath = keyPath
    let observation = observe(keyPath) { control, _ in
      guard isSetting.withLock({ !$0 }) else { return }
      MainActor._assumeIsolated {
        binding.wrappedValue = control[keyPath: uncheckedKeyPath]
      }
    }
    let observationToken = ObserveToken { [weak self] in
      MainActor._assumeIsolated {
        self?.actionProxy?.removeBindingAction(for: actionID)
      }
      token.cancel()
      observation.invalidate()
    }
    observationTokens[keyPath] = observationToken
    return observationToken
  }

  public func unbind<Value>(_ keyPath: KeyPath<NSFontManager, Value>) {
    observationTokens[keyPath]?.cancel()
    observationTokens[keyPath] = nil
  }
}

@MainActor
private let observationTokensKey = malloc(1)!
@MainActor
private let actionProxyKey = malloc(1)!

@MainActor
private class FontManagerProxy: NSObject {
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

  weak var owner: NSFontManager?

  required init(owner: NSFontManager) {
    self.owner = owner
    super.init()
    self.originTarget = owner.target
    self.originAction = owner.action
    owner.target = self
    owner.action = #selector(invokeAction(_:))
  }

  @objc func invokeAction(_ sender: Any?) {
    // NB: The font manager's target is 'nil' unless an app changes it: 'changeFont:' travels up
    //     the responder chain to whichever text view is first responder. Forward a 'nil' target
    //     as 'nil', which 'sendAction(_:to:from:)' routes there.
    if let originAction {
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
