import SwiftNavigation
import XCTest

class UITransactionTests: XCTestCase {
  #if compiler(>=6)
    func testTransactionKeyPropagates() async throws {
      try await Task { @MainActor in
        var tokens: Set<ObserveToken> = []
        let model = Model()
        XCTAssertEqual(UITransaction.current.isSet, false)

        var didObserve = false
        SwiftNavigation.observe {
          if model.count == 0 {
            XCTAssertEqual(UITransaction.current.isSet, false)
          } else if model.count == 1 {
            XCTAssertEqual(UITransaction.current.isSet, true)
          } else {
            XCTFail()
          }
          didObserve = true
        }
        .store(in: &tokens)

        withUITransaction(\.isSet, true) {
          model.count += 1
        }
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(didObserve, true)
        XCTAssertEqual(model.count, 1)
        XCTAssertEqual(UITransaction.current.isSet, false)
      }
      .value
    }

    func testTransactionMerging() {
      var tokens: Set<ObserveToken> = []
      SwiftNavigation.observe { transaction in
        XCTAssertFalse(transaction.isSet)
        XCTAssertFalse(transaction.isAlsoSet)
      }
      .store(in: &tokens)
      withUITransaction(\.isSet, true) {
        SwiftNavigation.observe { transaction in
          XCTAssertTrue(transaction.isSet)
          XCTAssertFalse(transaction.isAlsoSet)
        }
        .store(in: &tokens)
        withUITransaction(\.isAlsoSet, true) {
          SwiftNavigation.observe { transaction in
            XCTAssertTrue(transaction.isSet)
            XCTAssertTrue(transaction.isAlsoSet)
          }
          .store(in: &tokens)
        }
        SwiftNavigation.observe { transaction in
          XCTAssertTrue(transaction.isSet)
          XCTAssertFalse(transaction.isAlsoSet)
        }
        .store(in: &tokens)
      }
      SwiftNavigation.observe { transaction in
        XCTAssertFalse(transaction.isSet)
        XCTAssertFalse(transaction.isAlsoSet)
      }
      .store(in: &tokens)
    }

    func testSynchronousTransactionKey() async throws {
      try await Task { @MainActor in
        var tokens: Set<ObserveToken> = []
        let model = Model()
        XCTAssertEqual(UITransaction.current.isSet, false)

        var didObserve = false
        withUITransaction(\.isSet, true) {
          SwiftNavigation.observe {
            XCTAssertEqual(model.count, 0)
            XCTAssertEqual(UITransaction.current.isSet, true)
            didObserve = true
          }
          .store(in: &tokens)
        }

        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(didObserve, true)
        XCTAssertEqual(UITransaction.current.isSet, false)
      }
      .value
    }

    func testOverrideTransactionKey() async {
      XCTAssertEqual(UITransaction.current.isSet, false)
      withUITransaction(\.isSet, true) {
        XCTAssertEqual(UITransaction.current.isSet, true)
        withUITransaction(\.isSet, false) {
          XCTAssertEqual(UITransaction.current.isSet, false)
        }
      }
    }

    func testBindingTransactionKey() async throws {
      try await Task { @MainActor in
        var tokens: Set<ObserveToken> = []
        @UIBinding var count = 0
        var transaction = UITransaction()
        transaction.isSet = true

        var didObserve = false
        SwiftNavigation.observe {
          if count == 0 {
            XCTAssertEqual(UITransaction.current.isSet, false)
          } else if count == 1 {
            XCTAssertEqual(UITransaction.current.isSet, true)
          } else {
            XCTFail()
          }
          didObserve = true
        }
        .store(in: &tokens)

        let bindingWithTransaction = $count.transaction(transaction)
        bindingWithTransaction.wrappedValue = 1

        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(didObserve, true)
      }
      .value
    }
  #endif
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
