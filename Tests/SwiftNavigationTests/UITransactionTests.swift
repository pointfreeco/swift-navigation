import SwiftNavigation
import XCTest

class UITransactionTests: XCTestCase {
  @MainActor
  func testTransactionKeyPropagates() async throws {
    let model = Model()
    XCTAssertEqual(UITransaction.current.isSet, false)

    var didObserve = true
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
      model.count += 1
    }
    try await Task.sleep(for: .seconds(0.3))
    XCTAssertEqual(didObserve, true)
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
  func testBindingTransactionKey() async throws {
    @UIBinding var count = 0
    var transaction = UITransaction()
    transaction.isSet = true

    var didObserve = false
    observe {
      if count == 0 {
        XCTAssertEqual(UITransaction.current.isSet, false)
      } else if count == 1 {
        XCTAssertEqual(UITransaction.current.isSet, true)
      } else {
        XCTFail()
      }
      didObserve = true
    }

    let bindingWithTransaction = $count.transaction(transaction)
    bindingWithTransaction.wrappedValue = 1

    try await Task.sleep(for: .seconds(0.3))
    XCTAssertEqual(didObserve, true)
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
