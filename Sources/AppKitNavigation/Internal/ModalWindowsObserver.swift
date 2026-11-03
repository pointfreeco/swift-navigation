#if canImport(AppKit) && !targetEnvironment(macCatalyst)

public import AppKit
public import Combine

@MainActor
class ModalWindowsObserver: NSObject {
  static let shared = ModalWindowsObserver()

  var windowsCancellable: [NSWindow: AnyCancellable] = [:]

  var modalSessionByWindow: [NSWindow: NSApplication.ModalSession] = [:]

  /// Ends the window's modal session, or stops its modal loop, when the window closes.
  ///
  /// - Parameters:
  ///   - window: The window shown modally.
  ///   - modalSession: The session the window was shown in, if it was shown through
  ///     `beginModalSession(for:)` rather than a modal loop.
  ///   - onClose: Runs once the session has ended, after the window started closing.
  func observeWindow(
    _ window: NSWindow,
    modalSession: NSApplication.ModalSession? = nil,
    onClose: (() -> Void)? = nil
  ) {
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
        onClose?()
      }
  }
}

#endif
