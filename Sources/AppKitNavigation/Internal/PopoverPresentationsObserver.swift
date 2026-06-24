#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import Combine

@MainActor
final class PopoverPresentationsObserver: NSObject {
  static let shared = PopoverPresentationsObserver()

  var popoverCancellables: [NSPopover: AnyCancellable] = [:]

  func observePopover(_ popover: NSPopover, onDidClose: @escaping @MainActor () -> Void) {
    popoverCancellables[popover] = NotificationCenter.default
      .publisher(for: NSPopover.didCloseNotification, object: popover)
      .sink { [weak self] _ in
        MainActor._assumeIsolated {
          onDidClose()
          self?.popoverCancellables.removeValue(forKey: popover)
        }
      }
  }
}

#endif
