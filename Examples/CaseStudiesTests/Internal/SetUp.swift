import UIKit
import XCTest

extension XCTestCase {
  @MainActor
  func setUp(controller: UIViewController) async throws {
    guard
      let scene = UIApplication.shared.connectedScenes.first,
      let windowScene = scene as? UIWindowScene,
      let window = windowScene.windows.first
    else {
      struct WindowNotFound: Error {}
      throw WindowNotFound()
    }
    window.rootViewController = controller
    try await Task.sleep(for: .milliseconds(100))
  }
}
