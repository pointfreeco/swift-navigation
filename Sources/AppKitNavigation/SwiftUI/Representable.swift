#if canImport(SwiftUI) && canImport(AppKit) && !targetEnvironment(macCatalyst)
import SwiftUI
import AppKit

public struct NSViewControllerRepresenting<
    NSViewControllerType: NSViewController
>: NSViewControllerRepresentable {
    private let base: NSViewControllerType
    public init(_ base: () -> NSViewControllerType) {
        self.base = base()
    }

    public func makeNSViewController(context _: Context) -> NSViewControllerType { base }
    public func updateNSViewController(_: NSViewControllerType, context _: Context) {}
}

public struct NSViewRepresenting<NSViewType: NSView>: NSViewRepresentable {
    private let base: NSViewType
    public init(_ base: () -> NSViewType) {
        self.base = base()
    }

    public func makeNSView(context _: Context) -> NSViewType { base }
    public func updateNSView(_: NSViewType, context _: Context) {}
}
#endif
