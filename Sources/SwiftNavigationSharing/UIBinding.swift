@_spi(Navigation) import Sharing

/// Bridge helpers between `Sharing` and `SwiftNavigation`.
extension UIBinding {
  /// Creates a binding from a shared reference.
  ///
  /// Useful for binding shared state to UIKit, AppKit, and other `UIBinding`-based APIs.
  ///
  /// ```swift
  /// let count = Shared(value: 0)
  /// let binding = UIBinding(count)
  /// ```
  ///
  /// - Parameter base: A shared reference to a value.
  public init(_ base: Shared<Value>) {
    self.init(strongRoot: base._uiBindingRoot, keyPath: \.value)
  }
}
