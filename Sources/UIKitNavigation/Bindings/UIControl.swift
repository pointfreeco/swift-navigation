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

    // TODO: Make public?
    @available(iOS 14, *)
    func bind<Value>(
      _ binding: UIBinding<Value>,
      to keyPath: KeyPath<Self, Value>,
      for event: UIControl.Event,
      set: @escaping (Value, UITransaction) -> Void
    ) {
      if let observation = observations[keyPath] {
        observation.token.cancel()
        removeAction(observation.action, for: .allEvents)
      }
      let action = UIAction { [weak self] _ in
        guard let self else { return }
        binding.wrappedValue = self[keyPath: keyPath]
      }
      addAction(action, for: event)
      // TODO: Should we vendor LockIsolated?
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
      observations[keyPath] = Observation(action: action, observation: observation, token: token)
    }

    private var observations: [AnyKeyPath: Observation] {
      get {
        objc_getAssociatedObject(self, observationsKey) as? [AnyKeyPath: Observation] ?? [:]
      }
      set {
        objc_setAssociatedObject(
          self, observationsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
      }
    }
  }

  private final class Observation {
    let action: UIAction
    let observation: NSKeyValueObservation
    let token: ObservationToken

    init(action: UIAction, observation: NSKeyValueObservation, token: ObservationToken) {
      self.action = action
      self.observation = observation
      self.token = token
    }

    deinit {
      token.cancel()
    }
  }

  private let observationsKey = malloc(1)!
#endif
