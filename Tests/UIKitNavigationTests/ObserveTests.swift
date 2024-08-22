#if canImport(UIKit)
  import UIKitNavigation
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

    @MainActor
    func testTransactionKeyPropagates() async {
      let expectation = expectation(description: "onChange")
      expectation.expectedFulfillmentCount = 2

      let model = Model()
      XCTAssertEqual(UITransaction.current.isSet, false)

      observe {
        if model.count == 0 {
          XCTAssertEqual(UITransaction.current.isSet, false)
        } else if model.count == 1 {
          XCTAssertEqual(UITransaction.current.isSet, true)
        } else {
          XCTFail()
        }
        expectation.fulfill()
      }

      withUITransaction(\.isSet, true) {
        model.count += 1
      }
      await fulfillment(of: [expectation], timeout: 1)
      XCTAssertEqual(model.count, 1)
      XCTAssertEqual(UITransaction.current.isSet, false)
    }

    @MainActor
    func testTransactionKeyPropagatesWithAnimation() async {
      let expectation = expectation(description: "onChange")
      expectation.expectedFulfillmentCount = 2

      let model = Model()
      XCTAssertEqual(UITransaction.current.isSet, false)

      observe {
        if model.count == 0 {
          XCTAssertEqual(UITransaction.current.isSet, false)
        } else if model.count == 1 {
          XCTAssertEqual(UITransaction.current.isSet, true)
        } else {
          XCTFail()
        }
        expectation.fulfill()
      }

      withUITransaction(\.isSet, true) {
        withUIKitAnimation {
          model.count += 1
        }
      }
      await fulfillment(of: [expectation], timeout: 1)
      XCTAssertEqual(model.count, 1)
      XCTAssertEqual(UITransaction.current.isSet, false)
    }

    // TODO: write test for a transaction helper and make sure merging is happening under the hood

    @MainActor
    func testSynchronousTransactionKey() async {
      let expectation = expectation(description: "onChange")

      let model = Model()
      XCTAssertEqual(UITransaction.current.isSet, false)

      _ = withUITransaction(\.isSet, true) {
        observe {
          XCTAssertEqual(model.count, 0)
          XCTAssertEqual(UITransaction.current.isSet, true)
          expectation.fulfill()
        }
      }

      await fulfillment(of: [expectation], timeout: 1)
      XCTAssertEqual(UITransaction.current.isSet, false)
    }

    @MainActor
    func testOverrideTransactionKey() async {
      XCTAssertEqual(UITransaction.current.isSet, false)
      withUITransaction(\.isSet, true) {
        XCTAssertEqual(UITransaction.current.isSet, true)
        withUITransaction(\.isSet, false) {
          XCTAssertEqual(UITransaction.current.isSet, false)
        }
      }
    }

    @MainActor
    func testBindingTransactionKey() async {
      let expectation = expectation(description: "onChange")
      expectation.expectedFulfillmentCount = 2

      @UIBinding var count = 0
      var transaction = UITransaction()
      transaction.isSet = true

      observe {
        if count == 0 {
          XCTAssertEqual(UITransaction.current.isSet, false)
        } else if count == 1 {
          XCTAssertEqual(UITransaction.current.isSet, true)
        } else {
          XCTFail()
        }
        expectation.fulfill()
      }

      let bindingWithTransaction = $count.transaction(transaction)
      bindingWithTransaction.wrappedValue = 1

      await fulfillment(of: [expectation], timeout: 1)
    }
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
