#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSMenuItem: NSTargetActionProtocol, @unchecked Sendable {
    public var appkitNavigationTarget: AnyObject? {
        set { target = newValue }
        get { target }
    }

    public var appkitNavigationAction: Selector? {
        set { action = newValue }
        get { action }
    }
}

#endif
