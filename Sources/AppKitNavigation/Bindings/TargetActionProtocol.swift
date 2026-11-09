#if canImport(AppKit) && !targetEnvironment(macCatalyst)
@_spi(Internals) public import SwiftNavigation
public import AppKit

/// A protocol used to extend `NSControl, NSMenuItem...`.
@MainActor
public protocol TargetActionProtocol: NSObject, Sendable {
  var target: AnyObject? { set get }
  var action: Selector? { set get }
}

extension TargetActionProtocol {
  /// Establishes a two-way connection between a source of truth and a property of this control.
  ///
  /// - Parameters:
  ///   - binding: A source of truth for the control's value.
  ///   - keyPath: A key path to the control's value.
  /// - Returns: A cancel token.
  @discardableResult
  public func bind<Value>(
    _ binding: UIBinding<Value>,
    to keyPath: ReferenceWritableKeyPath<Self, Value>
  ) -> ObserveToken {
    bind(binding, to: keyPath) { control, newValue, _ in
      control[keyPath: keyPath] = newValue
    }
  }

  func createActionProxyIfNeeded() -> TargetActionProxy {
    if let actionProxy {
      return actionProxy
    } else {
      let actionProxy = TargetActionProxy(owner: self)
      self.actionProxy = actionProxy
      return actionProxy
    }
  }

  /// Establishes a two-way connection between a source of truth and a property of this control.
  ///
  /// - Parameters:
  ///   - binding: A source of truth for the control's value.
  ///   - keyPath: A key path to the control's value.
  ///   - set: A closure that is called when the binding's value changes with a weakly-captured
  ///     control, a new value that can be used to configure the control, and a transaction, which
  ///     can be used to determine how and if the change should be animated.
  /// - Returns: A cancel token.
  @discardableResult
  public func bind<Value>(
    _ binding: UIBinding<Value>,
    to keyPath: KeyPath<Self, Value>,
    set: @escaping (_ control: Self, _ newValue: Value, _ transaction: UITransaction) -> Void
  ) -> ObserveToken {
    establishBinding(binding, to: keyPath, of: self, through: createActionProxyIfNeeded(), set: set)
  }

  public func unbind<Value>(_ keyPath: KeyPath<Self, Value>) {
    removeBinding(to: keyPath)
  }

  @discardableResult
  public func addAction(_ action: @escaping (Self) -> Void) -> UUID {
    createActionProxyIfNeeded().addAction { [weak self] _ in
      guard let self else { return }
      action(self)
    }
  }

  public func removeAction(for id: UUID) {
    createActionProxyIfNeeded().removeAction(for: id)
  }

  public func removeAllActions() {
    createActionProxyIfNeeded().removeAllActions()
  }
}

/// Establishes a two-way connection between a binding and a property of an object: changes to
/// the binding are applied with `set`, and the user's changes are written back to the binding.
///
/// The user's changes arrive through the object's target-action pair, which `actionProxy` runs,
/// and through key-value observation of the property; either can be left out.
/// ``TargetActionProtocol`` and `NSFontManager` use both. The font manager cannot conform to the
/// protocol, since its `action` is not optional. Objects without a target-action pair, such as a
/// split view item, pass no proxy, and properties that key-value observation cannot reach, such
/// as the selection of one segment, opt out of it.
///
/// - Parameters:
///   - binding: The binding to keep in step with the property.
///   - keyPath: The property. The binding is stored under this key path, so binding the same
///     property again replaces it. It must be an Objective-C key path unless `observesKeyPath` is
///     `false`.
///   - owner: The object that has the property.
///   - actionProxy: The proxy that runs the object's target-action pair, or `nil` if it has none.
///   - observesKeyPath: Whether changes that key-value observation of the property reports are
///     written back too.
///   - valueAfterAction: The value to write back when the object sends its action, or `nil` to
///     leave the binding alone. Defaults to the property's value.
///   - set: Applies a new value of the binding to the object.
@MainActor
func establishBinding<Owner: NSObject, Value>(
  _ binding: UIBinding<Value>,
  to keyPath: KeyPath<Owner, Value>,
  of owner: Owner,
  through actionProxy: TargetActionProxy?,
  observesKeyPath: Bool = true,
  valueAfterAction: ((_ owner: Owner) -> Value?)? = nil,
  set: @escaping (_ owner: Owner, _ newValue: Value, _ transaction: UITransaction) -> Void
) -> ObserveToken {
  owner.removeBinding(to: keyPath)
  let actionID = actionProxy?.addBindingAction { [weak owner] _ in
    guard let owner else { return }
    if let valueAfterAction {
      guard let value = valueAfterAction(owner) else { return }
      binding.wrappedValue = value
    } else {
      binding.wrappedValue = owner[keyPath: keyPath]
    }
  }

  let isSetting = LockIsolated(false)
  let token = owner.observe { [weak owner] transaction in
    guard let owner else { return }
    isSetting.withLock { $0 = true }
    defer { isSetting.withLock { $0 = false } }
    set(
      owner,
      binding.wrappedValue,
      transaction.appKit.animation == nil && !transaction.appKit.disablesAnimations
        ? binding.transaction
        : transaction
    )
  }
  // NB: This key path must only be accessed on the main actor
  nonisolated(unsafe) let uncheckedKeyPath = keyPath
  let observation: NSKeyValueObservation?
  if observesKeyPath {
    observation = owner.observe(keyPath) { owner, _ in
      guard isSetting.withLock({ !$0 }) else { return }
      // NB: The owner need not be sendable — a split view item is explicitly not — but these
      //     objects only change, and so only report changes, on the main thread.
      nonisolated(unsafe) let owner = owner
      MainActor._assumeIsolated {
        binding.wrappedValue = owner[keyPath: uncheckedKeyPath]
      }
    }
  } else {
    observation = nil
  }
  let observationToken = ObserveToken { [weak actionProxy] in
    if let actionID {
      MainActor._assumeIsolated {
        actionProxy?.removeBindingAction(for: actionID)
      }
    }
    token.cancel()
    observation?.invalidate()
  }
  owner.observationTokens[keyPath] = observationToken
  return observationToken
}

@MainActor
extension NSObject {
  var observationTokens: [AnyKeyPath: ObserveToken] {
    get {
      objc_getAssociatedObject(self, observationTokensKey) as? [AnyKeyPath: ObserveToken]
        ?? [:]
    }
    set {
      objc_setAssociatedObject(
        self, observationTokensKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /// The proxy that runs this object's binding and closure actions, once one has been installed.
  var actionProxy: TargetActionProxy? {
    set {
      objc_setAssociatedObject(self, actionProxyKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    get {
      objc_getAssociatedObject(self, actionProxyKey) as? TargetActionProxy
    }
  }

  /// Cancels the binding established to `keyPath`, if there is one.
  func removeBinding(to keyPath: AnyKeyPath) {
    observationTokens[keyPath]?.cancel()
    observationTokens[keyPath] = nil
  }
}

@MainActor
private let observationTokensKey = malloc(1)!
@MainActor
private let actionProxyKey = malloc(1)!

#endif
