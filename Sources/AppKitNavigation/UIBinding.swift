#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import SwiftNavigation

  extension UIBinding {
    /// Specifies an animation to perform when the binding value changes.
    ///
    /// - Parameter animation: An animation sequence performed when the binding value changes.
    /// - Returns: A new binding.
    public func animation(_ animation: AppKitAnimation? = .default) -> Self {
      var binding = self
      binding.transaction.appKit.animation = animation
      return binding
    }
  }
#endif
