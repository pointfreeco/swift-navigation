#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import ConcurrencyExtras
@_spi(Internals) import SwiftNavigation
import AppKit

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
    ///   - event: The control-specific events for which the binding is updated.
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

    var actionProxy: TargetActionProxy? {
        set {
            objc_setAssociatedObject(self, actionProxyKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            objc_getAssociatedObject(self, actionProxyKey) as? TargetActionProxy
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
    ///   - event: The control-specific events for which the binding is updated.
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
        unbind(keyPath)
        let actionProxy = createActionProxyIfNeeded()
        let actionID = actionProxy.addBindingAction { [weak self] _ in
            guard let self else { return }
            binding.wrappedValue = self[keyPath: keyPath]
        }

        let isSetting = LockIsolated(false)
        let token = observe { [weak self] transaction in
            guard let self else { return }
            isSetting.withValue { $0 = true }
            defer { isSetting.withValue { $0 = false } }
            set(
                self,
                binding.wrappedValue,
                transaction.appKit.animation == nil && !transaction.appKit.disablesAnimations
                    ? binding.transaction
                    : transaction
            )
        }
        // NB: This key path must only be accessed on the main actor
        @UncheckedSendable var uncheckedKeyPath = keyPath
        let observation = observe(keyPath) { [$uncheckedKeyPath] control, _ in
            guard isSetting.withValue({ !$0 }) else { return }
            MainActor._assumeIsolated {
                binding.wrappedValue = control[keyPath: $uncheckedKeyPath.wrappedValue]
            }
        }
        let observationToken = ObserveToken { [weak self] in
            MainActor._assumeIsolated {
                self?.actionProxy?.removeAction(for: actionID)
            }
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
}

@MainActor
private let observationTokensKey = malloc(1)!
@MainActor
private let actionProxyKey = malloc(1)!

#endif
