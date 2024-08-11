import SwiftNavigation
import XCTest

class ObserveTests: XCTestCase {
  #if swift(>=6)
    @MainActor
    func testCompiles() {
      var count = 0
      let token = SwiftNavigation.observe {
        count = 1
      }
      XCTAssertEqual(count, 1)
      _ = token
    }
  #endif
}
