#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import Combine

@MainActor
class ModalWindowsObserver: NSObject {
    static let shared = ModalWindowsObserver()
    
    var windowsCancellable: [NSWindow: AnyCancellable] = [:]
    
    func observeWindow(_ window: NSWindow) {
        windowsCancellable[window] = NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: window)
            .sink { [weak self] _ in
                guard let self else { return }
                if NSApplication.shared.modalWindow === window {
                    NSApplication.shared.stopModal()
                }
                windowsCancellable.removeValue(forKey: window)
            }
    }
}

#endif
