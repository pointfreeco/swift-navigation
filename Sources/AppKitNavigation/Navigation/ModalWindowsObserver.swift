#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import Combine

@MainActor
class ModalWindowsObserver: NSObject {
    static let shared = ModalWindowsObserver()
    
    var windowsCancellable: [NSWindow: AnyCancellable] = [:]
    
    var modalSessionByWindow: [NSWindow: NSApplication.ModalSession] = [:]
    
    func observeWindow(_ window: NSWindow, modalSession: NSApplication.ModalSession? = nil) {
        if let modalSession {
            modalSessionByWindow[window] = modalSession
        }
        windowsCancellable[window] = NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: window)
            .sink { [weak self] _ in
                guard let self else { return }
                if let modalSession = modalSessionByWindow[window] {
                    NSApplication.shared.endModalSession(modalSession)
                } else if NSApplication.shared.modalWindow === window {
                    NSApplication.shared.stopModal()
                }
                modalSessionByWindow.removeValue(forKey: window)
                windowsCancellable[window]?.cancel()
                windowsCancellable.removeValue(forKey: window)
            }
    }
}

#endif
