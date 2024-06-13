#if canImport(UIKit)
  // TODO: `UISearchTextField(…, $tokens, $suggestedTokens)`?

  import ConcurrencyExtras
  @_spi(Internals) import SwiftNavigation
  import UIKit

  /// A protocol used to extend `UIControl`.
  @MainActor
  public protocol UIControlProtocol: UIControl {}

  extension UIControl: UIControlProtocol {}

  @available(iOS 14, *)
  extension UIControlProtocol {
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
      to keyPath: ReferenceWritableKeyPath<Self, Value>,
      for event: UIControl.Event
    ) -> ObservationToken {
      bind(binding, to: keyPath, for: event) { control, newValue, _ in
        control[keyPath: keyPath] = newValue
      }
    }

    /// Establishes a two-way connection between a source of truth and a property of this control.
    ///
    /// - Parameters:
    ///   - binding: A source of truth for the control's value.
    ///   - keyPath: A key path to the control's value.
    ///   - event: The control-specific events for which the binding is updated.
    ///   - set: A closure that is called when the binding's value changes.
    ///   - control: A weakly-captured `self` to be configured with a new value.
    ///   - newValue: A new value that can be used to configure the control.
    ///   - transaction: A transaction, which can be used to determine how and if the change should
    ///     be animated.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<Value>(
      _ binding: UIBinding<Value>,
      to keyPath: KeyPath<Self, Value>,
      for event: UIControl.Event,
      set: @escaping (_ control: Self, _ newValue: Value, _ transaction: UITransaction) -> Void
    ) -> ObservationToken {
      unbind(keyPath)
      let action = UIAction { [weak self] _ in
        guard let self else { return }
        binding.wrappedValue = self[keyPath: keyPath]
      }
      addAction(action, for: event)
      let isSetting = LockIsolated(false)
      let token = observe { [weak self] transaction in
        guard let self else { return }
        isSetting.setValue(true)
        defer { isSetting.setValue(false) }
        set(
          self,
          binding.wrappedValue,
          transaction.animation == nil && !transaction.disablesAnimations
            ? binding.transaction
            : transaction
        )
      }
      // NB: This key path must only be accessed on the main actor
      nonisolated(unsafe) let uncheckedKeyPath = keyPath
      let observation = observe(keyPath) { control, _ in
        guard !isSetting.value else { return }
        MainActor.assumeIsolated {
          binding.wrappedValue = control[keyPath: uncheckedKeyPath]
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

    public func unbind<Value>(_ keyPath: KeyPath<Self, Value>) {
      observationTokens[keyPath]?.cancel()
      observationTokens[keyPath] = nil
    }

    var observationTokens: [AnyKeyPath: ObservationToken] {
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

  @MainActor
  private let observationTokensKey = malloc(1)!
#endif
