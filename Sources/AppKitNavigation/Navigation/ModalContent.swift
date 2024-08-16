#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
public protocol ModalContent: NavigationContent {
    @discardableResult func runModal() -> NSApplication.ModalResponse
    var window: NSWindow { get }
}

extension NSWindow: ModalContent {
    public var window: NSWindow { self }

    public func runModal() -> NSApplication.ModalResponse {
        NSApplication.shared.runModal(for: self)
    }
}

extension NSAlert: ModalContent {}

#endif
