#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import SwiftNavigation

  extension UIBinding {
    public func animation(_ animation: AppKitAnimation? = .default) -> Self {
      var binding = self
      binding.transaction.appKit.animation = animation
      return binding
    }
  }
#endif
