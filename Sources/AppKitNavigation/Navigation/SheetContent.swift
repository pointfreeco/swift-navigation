#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
@objc
public protocol SheetContent: NavigationContent {
    var currentWindow: NSWindow? { get }
    func beginSheet(for content: SheetContent) async
    func endSheet(for content: SheetContent)
}

extension SheetContent {
    func _beginSheet(for content: any SheetContent) async {
        if let sheetedWindow = content.currentWindow {
            await currentWindow?.beginSheet(sheetedWindow)
        }
    }

    func _endSheet(for content: any SheetContent) {
        if let sheetedWindow = content.currentWindow {
            currentWindow?.endSheet(sheetedWindow)
        }
    }
}

extension NSWindow: SheetContent {
    public var currentWindow: NSWindow? { self }
    public func beginSheet(for content: any SheetContent) async {
        await _beginSheet(for: content)
    }
    public func endSheet(for content: any SheetContent) {
        _endSheet(for: content)
    }
}

extension NSWindowController: SheetContent {
    public var currentWindow: NSWindow? { window }
    public func beginSheet(for content: any SheetContent) async {
        await _beginSheet(for: content)
    }
    public func endSheet(for content: any SheetContent) {
        _endSheet(for: content)
    }
    
    public var onBeginNavigation: (() -> Void)? {
        set { _onBeginNavigation = newValue }
        get { _onBeginNavigation }
    }
    
    public var onEndNavigation: (() -> Void)? {
        set { _onEndNavigation = newValue }
        get { _onEndNavigation }
    }
}

extension NSViewController: SheetContent {
    public var currentWindow: NSWindow? { view.window }
    public func beginSheet(for content: any SheetContent) async {
        await _beginSheet(for: content)
    }
    public func endSheet(for content: any SheetContent) {
        _endSheet(for: content)
    }
    
    public var onBeginNavigation: (() -> Void)? {
        set { _onBeginNavigation = newValue }
        get { _onBeginNavigation }
    }
    
    public var onEndNavigation: (() -> Void)? {
        set { _onEndNavigation = newValue }
        get { _onEndNavigation }
    }
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

#endif
