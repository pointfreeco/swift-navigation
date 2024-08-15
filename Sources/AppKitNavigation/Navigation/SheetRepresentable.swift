#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
public protocol SheetRepresentable: NSObject {
    var currentWindow: NSWindow? { get }
    func beginSheet(for provider: SheetRepresentable) async
    func endSheet(for provider: SheetRepresentable)
}

extension SheetRepresentable {
    public func beginSheet(for provider: any SheetRepresentable) async {
        if let sheetedWindow = provider.currentWindow {
            await currentWindow?.beginSheet(sheetedWindow)
        }
    }

    public func endSheet(for provider: any SheetRepresentable) {
        if let sheetedWindow = provider.currentWindow {
            currentWindow?.endSheet(sheetedWindow)
        }
    }
}

extension NSWindow: SheetRepresentable {
    public var currentWindow: NSWindow? { self }
}

extension NSWindowController: SheetRepresentable {
    public var currentWindow: NSWindow? { window }
}

extension NSViewController: SheetRepresentable {
    public var currentWindow: NSWindow? { view.window }
}

extension NSAlert: SheetRepresentable {
    public var currentWindow: NSWindow? { window }

    public func beginSheet(for provider: any SheetRepresentable) async {
        guard let parentWindow = provider.currentWindow else { return }
        await beginSheetModal(for: parentWindow)
    }

    public func endSheet(for provider: any SheetRepresentable) {
        provider.currentWindow?.endSheet(window)
    }
}

#endif
