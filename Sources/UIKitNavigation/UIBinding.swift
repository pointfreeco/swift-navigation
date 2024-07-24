#if canImport(UIKit) && !os(watchOS)
  extension UIBinding {
    /// Specifies an animation to perform when the binding value changes.
    ///
    /// - Parameter animation: An animation sequence performed when the binding value changes.
    /// - Returns: A new binding.
    public func animation(_ animation: UIKitAnimation? = .default) -> Self {
      var binding = self
      binding.transaction.uiKit.animation = animation
      return binding
    }
  }
#endif
