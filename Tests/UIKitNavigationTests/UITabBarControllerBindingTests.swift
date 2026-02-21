#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
  import UIKit
  import UIKitNavigation
  import XCTest

  @available(iOS 18, visionOS 2, *)
  final class UITabBarControllerBindingTests: XCTestCase {
    @MainActor
    func testSelectedTabBindingUpdatesBothWays() async throws {
      @UIBinding var selectedIdentifier: String? = "first"
      let controller = UITabBarController()
      let firstTab = UITab(
        title: "First",
        image: nil,
        identifier: "first"
      ) { _ in
        UIViewController()
      }
      let secondTab = UITab(
        title: "Second",
        image: nil,
        identifier: "second"
      ) { _ in
        UIViewController()
      }

      controller.setTabs([firstTab, secondTab], animated: false)

      let token = controller.bind(selectedTab: $selectedIdentifier)
      defer { token.cancel() }

      await Task.yield()
      XCTAssertEqual(selectedIdentifier, "first")
      XCTAssertEqual(controller.selectedTab?.identifier, "first")

      selectedIdentifier = "second"
      await Task.yield()
      XCTAssertEqual(controller.selectedTab?.identifier, "second")

      controller.selectedIndex = 0
      await Task.yield()
      XCTAssertEqual(selectedIdentifier, "first")
    }
  }
#endif
