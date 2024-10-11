#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
protocol SheetContent: NavigationContent {
    var currentWindow: NSWindow? { get }
    func beginSheet(for content: SheetContent) async
    func endSheet(for content: SheetContent)
}

extension SheetContent {
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

extension NSWindowController: SheetContent {
    var currentWindow: NSWindow? { window }
}

extension NSViewController: SheetContent {
    var currentWindow: NSWindow? { view.window }
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

#endif
