#if canImport(SwiftUI) && canImport(UIKit) && !os(watchOS)
  import SwiftUI
  import UIKit

  /// Wraps a UIKit view controller in a SwiftUI view.
  ///
  /// Useful for rendering previews of view controllers in iOS 16 and earlier, where the `#Preview`
  /// macro is unavailable.
  @available(iOS 13, tvOS 13, *)
  @available(macOS, unavailable)
  @available(watchOS, unavailable)
  public struct UIViewControllerRepresenting<
    UIViewControllerType: UIViewController
  >: UIViewControllerRepresentable {
    private let base: UIViewControllerType
    public init(_ base: () -> UIViewControllerType) {
      self.base = _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
        base()
      }
    }
    public func makeUIViewController(context _: Context) -> UIViewControllerType { base }
    public func updateUIViewController(_: UIViewControllerType, context _: Context) {}
  }

  /// Wraps a UIKit view in a SwiftUI view.
  ///
  /// Useful for rendering previews of `UIView`s in iOS 16 and earlier, where the `#Preview` macro
  /// is unavailable.
  public struct UIViewRepresenting<UIViewType: UIView>: UIViewRepresentable {
    private let base: UIViewType
    public init(_ base: () -> UIViewType) {
      self.base = _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
        base()
      }
    }
    public func makeUIView(context _: Context) -> UIViewType { base }
    public func updateUIView(_: UIViewType, context _: Context) {}
  }
#endif
