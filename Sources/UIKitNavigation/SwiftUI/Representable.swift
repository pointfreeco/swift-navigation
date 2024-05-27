import SwiftUI

public struct UIViewControllerRepresenting<
  UIViewControllerType: UIViewController
>: UIViewControllerRepresentable {
  private let base: UIViewControllerType
  public init(_ base: () -> UIViewControllerType) {
    self.base = base()
  }
  public func makeUIViewController(context _: Context) -> UIViewControllerType { base }
  public func updateUIViewController(_: UIViewControllerType, context _: Context) {}
}

public struct UIViewRepresenting<UIViewType: UIView>: UIViewRepresentable {
  private let base: UIViewType
  public init(_ base: () -> UIViewType) {
    self.base = base()
  }
  public func makeUIView(context _: Context) -> UIViewType { base }
  public func updateUIView(_: UIViewType, context _: Context) {}
}
