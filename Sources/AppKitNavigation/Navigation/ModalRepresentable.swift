#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
@objc
public protocol ModalRepresentable where Self: NSObject {
    @objc @discardableResult func runModal() -> NSApplication.ModalResponse
    @objc var window: NSWindow { get }
}

extension NSWindow: ModalRepresentable {
    
    public var window: NSWindow { self }
    
    public func runModal() -> NSApplication.ModalResponse {
        NSApplication.shared.runModal(for: self)
    }
}

extension NSAlert: ModalRepresentable {}

#endif
