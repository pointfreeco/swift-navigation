#if canImport(UIKit)
  import SwiftUINavigation
  import XCTest

  class ObserveTests: XCTestCase {
    @MainActor
    func testCompiles() {
      var count = 0
      observe {
        count = 1
      }
      XCTAssertEqual(count, 1)
    }
  }
#endif
