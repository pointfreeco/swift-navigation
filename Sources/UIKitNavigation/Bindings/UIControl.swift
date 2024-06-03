#if canImport(UIKit)
  import ConcurrencyExtras
  @_spi(Internals) import SwiftNavigation
  import UIKit

  @MainActor
  protocol _UIControl: UIControl {}

  extension UIControl: _UIControl {}

  extension _UIControl {
    /// Establishes a two-way connection between a source of truth and a property of this control.
    ///
    /// - Parameters:
    ///   - binding: A source of truth for the control's value.
    ///   - keyPath: A key path to the control's value.
    ///   - event: The control-specific events for which the binding is updated.
    @available(iOS 14, *)
    public func bind<Value>(
      _ binding: UIBinding<Value>,
      to keyPath: ReferenceWritableKeyPath<Self, Value>,
      for event: UIControl.Event
    ) {
      bind(binding, to: keyPath, for: event) { [weak self] newValue, _ in
        self?[keyPath: keyPath] = newValue
      }
    }

    /// Establishes a two-way connection between a source of truth and a property of this control.
    ///
    /// - Parameters:
    ///   - binding: A source of truth for the control's value.
    ///   - keyPath: A key path to the control's value.
    ///   - event: The control-specific events for which the binding is updated.
    ///   - set: A closure that is called when the binding's value changes with the new value and
    ///     the current transaction, which can be used to determine if the change should be
    ///     animated.
    @available(iOS 14, *)
    @discardableResult
    public func bind<Value>(
      _ binding: UIBinding<Value>,
      to keyPath: KeyPath<Self, Value>,
      for event: UIControl.Event,
      set: @escaping (_ newValue: Value, _ transaction: UITransaction) -> Void
    ) -> ObservationToken {
      let action = UIAction { [weak self] _ in
        guard let self else { return }
        binding.wrappedValue = self[keyPath: keyPath]
      }
      addAction(action, for: event)
      let isSetting = LockIsolated(false)
      let weakBinding = UIBinding(weak: binding)
      let token = observe { transaction in
        isSetting.setValue(true)
        defer { isSetting.setValue(false) }
        set(
          weakBinding.wrappedValue,
          transaction.animation == nil && !transaction.disablesAnimations
            ? weakBinding.transaction
            : transaction
        )
      }
      let observation = observe(keyPath) { [weak self] _, _ in
        guard let self else { return }
        if !isSetting.value {
          MainActor.assumeIsolated {
            binding.wrappedValue = self[keyPath: keyPath]
          }
        }
      }
      let observationToken = ObservationToken { [weak self] in
        MainActor.assumeIsolated { self?.removeAction(action, for: .allEvents) }
        token.cancel()
        observation.invalidate()
      }
      observationTokens[keyPath] = observationToken
      return observationToken
    }

    private var observationTokens: [AnyKeyPath: ObservationToken] {
      get {
        objc_getAssociatedObject(self, observationTokensKey) as? [AnyKeyPath: ObservationToken]
          ?? [:]
      }
      set {
        objc_setAssociatedObject(
          self, observationTokensKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
      }
    }
  }

  private let observationTokensKey = malloc(1)!
#endif
