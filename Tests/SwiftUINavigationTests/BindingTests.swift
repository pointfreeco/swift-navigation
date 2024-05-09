#if swift(>=5.9) && canImport(SwiftUI)
  import CustomDump
  import SwiftUI
  import SwiftUINavigation
  import XCTest

  final class BindingTests: XCTestCase {
    @CasePathable
    @dynamicMemberLookup
    enum Status: Equatable {
      case inStock(quantity: Int)
      case outOfStock(isOnBackOrder: Bool)
    }

    func testCaseLookup() throws {
      @Binding var status: Status
      _status = Binding(initialValue: .inStock(quantity: 1))

      let inStock = try XCTUnwrap($status.inStock)
      inStock.wrappedValue += 1

      XCTAssertEqual(status, .inStock(quantity: 2))
    }

    func testCaseCannotReplaceOtherCase() throws {
      @Binding var status: Status
      _status = Binding(initialValue: .inStock(quantity: 1))

      let inStock = try XCTUnwrap($status.inStock)

      status = .outOfStock(isOnBackOrder: true)

      inStock.wrappedValue = 42
      XCTAssertEqual(status, .outOfStock(isOnBackOrder: true))
    }

    func testDestinationCannotReplaceOtherDestination() throws {
      @Binding var destination: Status?
      _destination = Binding(initialValue: .inStock(quantity: 1))

      let inStock = try XCTUnwrap($destination.inStock)

      destination = .outOfStock(isOnBackOrder: true)

      inStock.wrappedValue = 42
      XCTAssertEqual(destination, .outOfStock(isOnBackOrder: true))
    }
  }

  extension Binding {
    fileprivate init(initialValue: Value) {
      var value = initialValue
      self.init(
        get: { value },
        set: { value = $0 }
      )
    }
  }
#endif  // canImport(SwiftUI)
