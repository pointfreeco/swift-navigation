#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
public protocol SheetContent: NavigationContent {
    var currentWindow: NSWindow? { get }
    func beginSheet(for content: SheetContent) async
    func endSheet(for content: SheetContent)
}

extension SheetContent {
    public func beginSheet(for content: any SheetContent) async {
        guard let sheetedWindow = content.currentWindow else { return }
        await currentWindow?.beginSheet(sheetedWindow)
    }

    public func endSheet(for content: any SheetContent) {
        guard let sheetedWindow = content.currentWindow else { return }
        currentWindow?.endSheet(sheetedWindow)
    }
}

extension NSWindow: SheetContent {
    public var currentWindow: NSWindow? { self }
}

extension NSWindowController: SheetContent {
    public var currentWindow: NSWindow? { window }
}

extension NSViewController: SheetContent {
    public var currentWindow: NSWindow? { view.window }
}

extension NSAlert: SheetContent {
    public var currentWindow: NSWindow? { window }

    public func beginSheet(for content: any SheetContent) async {
        guard let parentWindow = content.currentWindow else { return }
        await beginSheetModal(for: parentWindow)
    }

    public func endSheet(for content: any SheetContent) {
        content.currentWindow?.endSheet(window)
    }
}

extension NSSavePanel {
    public func beginSheet(for content: any SheetContent) async {
        guard let parentWindow = content.currentWindow else { return }
        await beginSheetModal(for: parentWindow)
    }

    public func endSheet(for content: any SheetContent) {
        content.currentWindow?.endSheet(window)
    }
}

#endif
