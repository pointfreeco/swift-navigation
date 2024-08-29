#if canImport(UIKit)
  import SwiftNavigation
  import UIKitNavigation
  import XCTest

  class UITransactionTests: XCTestCase {
    #if !os(watchOS)
      @MainActor
      func testTransactionKeyPropagatesWithAnimation() async throws {
        let expectation = expectation(description: "onChange")
        expectation.expectedFulfillmentCount = 2

        let model = Model()
        XCTAssertEqual(UITransaction.current.isSet, false)

        var didObserve = false
        observe {
          if model.count == 0 {
            XCTAssertEqual(UITransaction.current.isSet, false)
          } else if model.count == 1 {
            XCTAssertEqual(UITransaction.current.isSet, true)
          } else {
            XCTFail()
          }
          didObserve = true
        }

        withUITransaction(\.isSet, true) {
          withUIKitAnimation {
            model.count += 1
          }
        }
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(didObserve, true)
        XCTAssertEqual(model.count, 1)
        XCTAssertEqual(UITransaction.current.isSet, false)
      }
    #endif
  }

  @Perceptible
  private class Model {
    var count = 0
  }

  private enum IsSetKey: UITransactionKey {
    static let defaultValue = false
  }
  extension UITransaction {
    var isSet: Bool {
      get { self[IsSetKey.self] }
      set { self[IsSetKey.self] = newValue }
    }
  }
#endif
