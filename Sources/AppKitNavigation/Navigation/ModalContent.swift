#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
protocol ModalContent: NavigationContent {
  @discardableResult func appKitNavigationRunModal() -> NSApplication.ModalResponse
  var window: NSWindow { get }
}

@MainActor
protocol ModalSessionContent: ModalContent {
  func appKitNavigationBeginModalSession() -> NSApplication.ModalSession
}

extension NSWindow: ModalContent {
  var window: NSWindow { self }

  func appKitNavigationRunModal() -> NSApplication.ModalResponse {
    __appKitNavigationRunModal()
  }

  @objc func __appKitNavigationRunModal() -> NSApplication.ModalResponse {
    NSApplication.shared.runModal(for: self)
  }
}

extension NSWindow: ModalSessionContent {
  func appKitNavigationBeginModalSession() -> NSApplication.ModalSession {
    NSApplication.shared.beginModalSession(for: self)
  }
}

extension NSSavePanel {
  override func __appKitNavigationRunModal() -> NSApplication.ModalResponse {
    runModal()
  }
}

extension NSAlert: ModalContent {
  func appKitNavigationRunModal() -> NSApplication.ModalResponse {
    runModal()
  }
}

#endif
