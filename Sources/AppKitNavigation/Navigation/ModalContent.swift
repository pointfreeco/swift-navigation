#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
public protocol ModalContent: NavigationContent {
    @discardableResult func appKitNavigationRunModal() -> NSApplication.ModalResponse
    var window: NSWindow { get }
}

extension NSWindow: ModalContent {
    public var window: NSWindow { self }

    public func appKitNavigationRunModal() -> NSApplication.ModalResponse {
        __appKitNavigationRunModal()
    }
    
    @objc func __appKitNavigationRunModal() -> NSApplication.ModalResponse {
        NSApplication.shared.runModal(for: self)
    }
}

extension NSSavePanel {
    override func __appKitNavigationRunModal() -> NSApplication.ModalResponse {
        runModal()
    }
}

extension NSAlert: ModalContent {
    public func appKitNavigationRunModal() -> NSApplication.ModalResponse {
        runModal()
    }
}

#endif
