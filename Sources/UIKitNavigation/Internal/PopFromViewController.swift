#if canImport(UIKit) && !os(watchOS)
  import UIKit

  extension UINavigationController {
    @discardableResult
    func popFromViewController(
      _ controller: UIViewController, animated: Bool
    ) -> [UIViewController]? {
      guard let index = viewControllers.firstIndex(of: controller), index != 0 else { return nil }
      return popToViewController(viewControllers[index - 1], animated: animated)
    }
  }
#endif
