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
        createActionHandlerIfNeeded().addAction { [weak self] _ in
            guard let self else { return }
            action(self)
        }
    }
}

#endif
