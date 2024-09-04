#if canImport(UIKit)
  import UIKitNavigation
import SwiftUI
  import XCTest

@available(iOS 16.0, *)
  class ObserveTests: XCTestCase {
    @MainActor
    func testCompiles() {
      var count = 0
      observe {
        count = 1
      }
      XCTAssertEqual(count, 1)
    }

    @MainActor
    func testPerceptionCheckingInNavigationStackController() async throws {
      struct RootView: View {
        @UIBindable var model = AppModel()
        var body: some View {
          UIViewControllerRepresenting {
            NavigationStackController(path: $model.path) {
              UIViewController()
            }
          }
        }
      }

      try await render(RootView())
    }

    @MainActor
    private func render(_ view: some View) async throws  {
      let image = ImageRenderer(content: view).cgImage
      _ = image
      try await Task.sleep(for: .seconds(0.1))
    }
  }

//extension NavigationStackController

@Perceptible
private class AppModel: HashableObject {
  var path: [Int] = []
}
#endif
