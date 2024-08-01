import UIKit

extension UIViewController {
  func mediumDetents() {
    if let sheet = sheetPresentationController {
      sheet.detents = [.medium()]
      sheet.prefersScrollingExpandsWhenScrolledToEdge = false
      sheet.prefersEdgeAttachedInCompactHeight = true
      sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
    }
  }
}
