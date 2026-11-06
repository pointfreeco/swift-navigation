#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import AppKitNavigationShim
import SwiftNavigation

@MainActor
protocol SheetContent: NavigationContent {
  var currentWindow: NSWindow? { get }
  var attachedContent: (any SheetContent)? { get }
  func beginSheet(for content: any SheetContent) async
  func endSheet(for content: any SheetContent)
}

extension SheetContent {
  var attachedContent: (any SheetContent)? { currentWindow?.attachedSheet }
  
  func beginSheet(for content: any SheetContent) async {
    guard let sheetedWindow = content.currentWindow else { return }
    await currentWindow?.beginSheet(sheetedWindow)
  }

  func endSheet(for content: any SheetContent) {
    guard let sheetedWindow = content.currentWindow else { return }
    currentWindow?.endSheet(sheetedWindow)
  }
}

extension NSWindow: SheetContent {
  var currentWindow: NSWindow? { self }
}

extension NSAlert: SheetContent {
  var currentWindow: NSWindow? { window }

  func beginSheet(for content: any SheetContent) async {
    guard let parentWindow = content.currentWindow else { return }
    await beginSheetModal(for: parentWindow)
  }

  func endSheet(for content: any SheetContent) {
    content.currentWindow?.endSheet(window)
  }
}

extension NSSavePanel {
  func beginSheet(for content: any SheetContent) async {
    guard let parentWindow = content.currentWindow else { return }
    await beginSheetModal(for: parentWindow)
  }

  func endSheet(for content: any SheetContent) {
    content.currentWindow?.endSheet(self)
  }
}

extension NSViewController: SheetContent {
  var currentWindow: NSWindow? { view.window }

  var attachedContent: (any SheetContent)? { currentWindow?.attachedSheet?.contentViewController }

  func beginSheet(for content: any SheetContent) async {
    guard let viewController = content as? NSViewController else { return }
    // NB: Unlike a window's 'beginSheet', 'presentAsSheet' returns as soon as the sheet is up, and
    //     the caller resets the binding the moment this returns. Suspend until the sheet is
    //     dismissed instead, which the shim reports from the dismissed controller's
    //     'viewDidDisappear'.
    await withCheckedContinuation { continuation in
      MainActor._assumeIsolated {
        let onDismiss = viewController._AppKitNavigation_onDismiss
        viewController._AppKitNavigation_onDismiss = {
          onDismiss?()
          continuation.resume()
        }
        presentAsSheet(viewController)
      }
    }
  }
  
  func endSheet(for content: any SheetContent) {
    guard let viewController = content as? NSViewController else { return }
    dismiss(viewController)
  }
}

#endif
