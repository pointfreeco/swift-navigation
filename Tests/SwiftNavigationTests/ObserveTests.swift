import SwiftNavigation
import XCTest

class ObserveTests: XCTestCase {
  #if swift(>=6)
//    @MainActor
    func testIsolation() async {
      await MainActor.run {
        var count = 0
        let token = SwiftNavigation.observe {
          count = 1
        }
        XCTAssertEqual(count, 1)
        _ = token
      }
    }
  #endif

//  @MainActor
  func testTokenStorage() async {
    await MainActor.run {
      var count = 0
      var tokens: Set<ObserveToken> = []
      SwiftNavigation.observe {
        count += 1
      }
      .store(in: &tokens)
      SwiftNavigation.observe {
        count += 1
      }
      .store(in: &tokens)
      XCTAssertEqual(count, 2)
    }
  }
}
