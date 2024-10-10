#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
public protocol ModalSessionContent: ModalContent {
    func appKitNavigationBeginModalSession() -> NSApplication.ModalSession
}

extension NSWindow: ModalSessionContent {

    public func appKitNavigationBeginModalSession() -> NSApplication.ModalSession {
        NSApplication.shared.beginModalSession(for: self)
    }
}

#endif
