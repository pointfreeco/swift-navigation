#if swift(>=6)
  import SwiftNavigation
  import XCTest

  final class LifetimeTests: XCTestCase {
    @MainActor
    func testObserveToken() async {
      let model = Model()
      var counts = [Int]()
      var token: ObserveToken?
      do {
        token = SwiftNavigation.observe {
          counts.append(model.count)
        }
      }
      XCTAssertEqual(counts, [0])
      model.count += 1
      await Task.yield()
      XCTAssertEqual(counts, [0, 1])

      _ = token
      token = nil

      model.count += 1
      await Task.yield()
      XCTAssertEqual(counts, [0, 1])
    }
  }

  @Perceptible
  @MainActor
  class Model {
    var count = 0
  }
#endif
