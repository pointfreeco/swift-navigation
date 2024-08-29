#if swift(>=6)
  import SwiftNavigation
  import XCTest

  final class LifetimeTests: XCTestCase {
    func testObserveToken() async {
      await Task { @MainActor in
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
      .value
    }
  }

  @Perceptible
  @MainActor
  private class Model {
    var count = 0
  }
#endif
