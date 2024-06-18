import UIKitNavigation
import XCTest

final class RuntimeWarningTests: XCTestCase {
  @MainActor
  func testDismissWhenNotPresented() async throws {
    XCTExpectFailure {
      let vc = UIViewController()
      vc.traitCollection.dismiss()
    } issueMatcher: {
      $0.compactDescription == """
        A view controller requested dismissal, but couldn't be dismissed.

        'UITraitCollection.dismiss()' must be called from an object that was presented using a \
        binding, for example 'UIViewController.present(item:)', and \
        'UIViewController.navigationDestination(item:)'.
        """
    }
  }

  @MainActor
  func testNavigationDestination_WithoutNavigationController() async throws {
    class VC: UIViewController {
      
    }
  }
}
