#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
protocol SheetContent: NavigationContent {
  var currentWindow: NSWindow? { get }
  var attachedContent: SheetContent? { get }
  func beginSheet(for content: SheetContent) async
  func endSheet(for content: SheetContent)
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
    content.currentWindow?.endSheet(window)
  }
}

extension NSViewController: SheetContent {
  var currentWindow: NSWindow? { view.window }
  
  var attachedContent: (any SheetContent)? { currentWindow?.attachedSheet?.contentViewController }
  
  func beginSheet(for content: any SheetContent) async {
    guard let viewController = content as? NSViewController else { return }
    presentAsSheet(viewController)
  }
  
  func endSheet(for content: any SheetContent) {
    guard let viewController = content as? NSViewController else { return }
    dismiss(viewController)
  }
}

#endif
