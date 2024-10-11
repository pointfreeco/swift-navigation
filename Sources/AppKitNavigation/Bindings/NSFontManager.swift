#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import SwiftNavigation

extension NSFontManager: NSTargetActionProtocol, @unchecked Sendable {
    public var appkitNavigationTarget: AnyObject? {
        set { appkitNavigationDelegate.target = newValue }
        get { appkitNavigationDelegate.target }
    }

    public var appkitNavigationAction: Selector? {
        set { appkitNavigationDelegate.action = newValue }
        get { appkitNavigationDelegate.action }
    }

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

#endif
