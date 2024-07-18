import UIKit

extension UINavigationController {
  @discardableResult
  func popFromViewController(
    _ controller: UIViewController, animated: Bool, completion: (() -> Void)? = nil
  ) -> [UIViewController]? {
    guard let index = viewControllers.firstIndex(of: controller), index != 0 else { return nil }
    let popped = popToViewController(viewControllers[index - 1], animated: animated)
    doAfterAnimatingTransition(animated: animated) { completion?() }
    return popped
  }

  private func doAfterAnimatingTransition(animated: Bool, completion: @escaping () -> Void) {
    if let coordinator = transitionCoordinator, animated {
      coordinator.animate(alongsideTransition: nil) { _ in completion() }
    } else {
      completion()
    }
  }
}
