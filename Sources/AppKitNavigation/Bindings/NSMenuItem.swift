#if canImport(AppKit) && !targetEnvironment(macCatalyst)

public import AppKit

extension NSMenuItem: TargetActionProtocol, @unchecked @retroactive Sendable {}

// NB: A menu item is not isolated to the main actor, but bindings are.
@MainActor
extension NSMenuItem {
    /// Creates a menu item with the specified title whose checkmark follows a binding.
    ///
    /// - Parameters:
    ///   - title: The title of the menu item.
    ///   - isOn: The binding to read from for whether the menu item shows a checkmark, and write
    ///     to when the user chooses it.
    ///   - keyEquivalent: The key equivalent of the menu item.
    public convenience init(title: String, isOn: UIBinding<Bool>, keyEquivalent: String = "") {
        self.init(title: title, action: nil, keyEquivalent: keyEquivalent)
        bind(isOn: isOn)
    }

    /// Establishes a two-way connection between a binding and the menu item's checkmark.
    ///
    /// The menu item shows a checkmark while the bound value is `true`, and choosing it toggles
    /// the value.
    ///
    /// ```swift
    /// viewMenu.addItem(NSMenuItem(title: "Show Hidden Files", isOn: $model.showsHiddenFiles))
    /// ```
    ///
    /// - Parameter isOn: The binding to read from for whether the menu item shows a checkmark,
    ///   and write to when the user chooses it.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(isOn: UIBinding<Bool>) -> ObserveToken {
        // NB: Choosing a menu item sends its action without changing its state, so the action
        //     writes back the opposite of what the checkmark showed.
        establishBinding(
            isOn,
            to: \.appKitNavigationIsOn,
            of: self,
            through: createActionProxyIfNeeded(),
            valueAfterAction: { menuItem in !menuItem.appKitNavigationIsOn }
        ) { menuItem, isOn, _ in
            menuItem.appKitNavigationIsOn = isOn
        }
    }

    // NB: Exposed to Objective-C so the binding can observe it, and named after the library so
    //     that it can never replace a method AppKit has, or adds later, under the same selector.
    @objc var appKitNavigationIsOn: Bool {
        set { state = newValue ? .on : .off }
        get { state == .on }
    }
}

#endif
