import SwiftNavigation
import XCTest

class UITransactionTests: XCTestCase {
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
  func testTransactionMerging() async {
    observe { transaction in
      XCTAssertFalse(transaction.isSet)
      XCTAssertFalse(transaction.isAlsoSet)
    }
    withUITransaction(\.isSet, true) {
      observe { transaction in
        XCTAssertTrue(transaction.isSet)
        XCTAssertFalse(transaction.isAlsoSet)
      }
      _ = withUITransaction(\.isAlsoSet, true) {
        observe { transaction in
          XCTAssertTrue(transaction.isSet)
          XCTAssertTrue(transaction.isAlsoSet)
        }
      }
      observe { transaction in
        XCTAssertTrue(transaction.isSet)
        XCTAssertFalse(transaction.isAlsoSet)
      }
    }
    observe { transaction in
      XCTAssertFalse(transaction.isSet)
      XCTAssertFalse(transaction.isAlsoSet)
    }
  }

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

extension UITransaction {
  var isSet: Bool {
    get { self[IsSetKey.self] }
    set { self[IsSetKey.self] = newValue }
  }
  var isAlsoSet: Bool {
    get { self[IsAlsoSetKey.self] }
    set { self[IsAlsoSetKey.self] = newValue }
  }
}
private enum IsSetKey: UITransactionKey {
  static let defaultValue = false
}
private enum IsAlsoSetKey: UITransactionKey {
  static let defaultValue = false
}
