#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import ConcurrencyExtras
@_spi(Internals) import SwiftNavigation
import AppKit

/// A protocol used to extend `NSControl, NSMenuItem...`.
@MainActor
public protocol NSTargetActionProtocol: NSObject, Sendable {
    var appkitNavigationTarget: AnyObject? { set get }
    var appkitNavigationAction: Selector? { set get }
}

@MainActor
internal class NSTargetActionHandler: NSObject {
    let action: (NSControl) -> Void

    var originTarget: AnyObject?
    
    var originAction: Selector?
    
    init(action: @escaping (NSControl) -> Void) {
        self.action = action
    }

    @objc func invokeAction(_ sender: NSControl) {
        if let originTarget, let originAction {
            NSApplication.shared.sendAction(originAction, to: originTarget, from: sender)
        }
        action(sender)
        
    }
}


extension NSTargetActionProtocol {
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
    ) -> ObservationToken {
        bind(binding, to: keyPath) { control, newValue, _ in
            control[keyPath: keyPath] = newValue
        }
    }

    
    
    internal var actionHandler: NSTargetActionHandler? {
        set { objc_setAssociatedObject(self, actionHandlerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { objc_getAssociatedObject(self, actionHandlerKey) as? NSTargetActionHandler }
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
    ) -> ObservationToken {
        unbind(keyPath)
        let actionHandler = NSTargetActionHandler { [weak self] _ in
            guard let self else { return }
            binding.wrappedValue = self[keyPath: keyPath]
        }
        self.actionHandler = actionHandler
        appkitNavigationTarget = actionHandler
        appkitNavigationAction = #selector(NSTargetActionHandler.invokeAction(_:))

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
        let observationToken = ObservationToken { [weak self] in
            MainActor._assumeIsolated {
                self?.appkitNavigationTarget = nil
                self?.appkitNavigationAction = nil
                self?.actionHandler = nil
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
@MainActor
private let actionHandlerKey = malloc(1)!

#endif
