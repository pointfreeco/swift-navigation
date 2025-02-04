#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import ConcurrencyExtras
@_spi(Internals) import SwiftNavigation
import AppKit
import IdentifiedCollections

@MainActor
extension NSFontManager: @unchecked @retroactive Sendable {
    
   private static let appkitNavigationDelegateKey = malloc(1)!

    private var appkitNavigationDelegate: Delegate {
        set {
            objc_setAssociatedObject(self, Self.appkitNavigationDelegateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let delegate = objc_getAssociatedObject(self, Self.appkitNavigationDelegateKey) as? Delegate {
                return delegate
            } else {
                let delegate = Delegate()
                target = delegate
                self.appkitNavigationDelegate = delegate
                return delegate
            }
        }
    }

    private class Delegate: NSObject, NSFontChanging {
        var target: AnyObject?
        var action: Selector?

        func changeFont(_ sender: NSFontManager?) {
            if let action {
                NSApplication.shared.sendAction(action, to: target, from: sender)
            }
        }
    }
}

@MainActor
extension NSFontManager {
    /// Creates a new date picker with the specified frame and registers the binding against the
    /// selected date.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - date: The binding to read from for the selected date, and write to when the selected
    ///     date changes.
    public convenience init(font: UIBinding<NSFont>) {
        self.init()
        bind(font: font)
    }

    /// Establishes a two-way connection between a binding and the date picker's selected date.
    ///
    /// - Parameter date: The binding to read from for the selected date, and write to when the
    ///   selected date changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(font: UIBinding<NSFont>) -> ObserveToken {
        bind(font, to: \._selectedFont)
    }

    @objc private var _selectedFont: NSFont {
        set { setSelectedFont(newValue, isMultiple: false) }
        get { convert(.systemFont(ofSize: 0)) }
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

    @objc func controlTextDidChange(_ obj: Notification) {
        bindingActions.forEach { $0.invoke(obj.object) }
        actions.forEach { $0.invoke(obj.object) }
    }

    @objc func invokeAction(_ sender: Any?) {
        if let originTarget, let originAction {
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
