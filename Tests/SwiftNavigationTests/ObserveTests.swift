import SwiftNavigation
import XCTest

class ObserveTests: XCTestCase {
  #if swift(>=6)
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

  #if !os(WASI)
    @MainActor
    func testTokenStorage() async {
      var count = 0
      var tokens: Set<ObserveToken> = []
      observe {
        count += 1
      }
      .store(in: &tokens)
      observe {
        count += 1
      }
      .store(in: &tokens)
      XCTAssertEqual(count, 2)
    }
  #endif
}
