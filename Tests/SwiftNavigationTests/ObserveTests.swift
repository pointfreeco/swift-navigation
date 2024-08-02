import SwiftNavigation
import XCTest

class ObserveTests: XCTestCase {
  @MainActor
  func testCompiles() {
    var count = 0
    let token = SwiftNavigation.observe {
      count = 1
    }
    XCTAssertEqual(count, 1)
    _ = token 
  }
}
