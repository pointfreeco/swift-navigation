#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSControl: NSTargetActionProtocol {
    public var appkitNavigationTarget: AnyObject? {
        set { target = newValue }
        get { target }
    }

    public var appkitNavigationAction: Selector? {
        set { action = newValue }
        get { action }
    }
}

extension NSControl {
    public convenience init(action: @escaping (Self) -> Void) {
        self.init(frame: .zero)
        createActionProxyIfNeeded().addAction { [weak self] _ in
            guard let self else { return }
            action(self)
        }
    }

    public func addAction(_ action: @escaping (NSControl) -> Void) {
        createActionProxyIfNeeded().addAction { [weak self] _ in
            guard let self else { return }
            action(self)
        }
    }

    public func removeAllActions() {
        createActionProxyIfNeeded().removeAllActions()
    }
}

#endif
