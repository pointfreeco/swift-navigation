#if canImport(SwiftUI) && canImport(AppKit)
  import AppKit
  import SwiftUI

  /// Wraps an AppKit view controller in a SwiftUI view.
  ///
  /// Useful for rendering previews of view controllers in macOS 13 and earlier, where the
  /// `#Preview` macro is unavailable.
  public struct NSViewControllerRepresenting<
    NSViewControllerType: NSViewController
  >: NSViewControllerRepresentable {
    private let base: NSViewControllerType
    public init(_ base: () -> NSViewControllerType) {
      self.base = _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
        base()
      }
    }
    public func makeNSViewController(context _: Context) -> NSViewControllerType { base }
    public func updateNSViewController(_: NSViewControllerType, context _: Context) {}
  }

  /// Wraps an AppKit view in a SwiftUI view.
  ///
  /// Useful for rendering previews of `NSView`s in macOS 13 and earlier, where the `#Preview` macro
  /// is unavailable.
  public struct NSViewRepresenting<NSViewType: NSView>: NSViewRepresentable {
    private let base: NSViewType
    public init(_ base: () -> NSViewType) {
      self.base = _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
        base()
      }
    }
    public func makeNSView(context _: Context) -> NSViewType { base }
    public func updateNSView(_: NSViewType, context _: Context) {}
  }
#endif
