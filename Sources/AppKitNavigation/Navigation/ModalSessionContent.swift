#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
protocol ModalSessionContent: ModalContent {
    func appKitNavigationBeginModalSession() -> NSApplication.ModalSession
}

extension NSWindow: ModalSessionContent {
    func appKitNavigationBeginModalSession() -> NSApplication.ModalSession {
        NSApplication.shared.beginModalSession(for: self)
    }
}

#endif
