#if CasePaths
  import CasePaths
  import SwiftNavigation
  import XCTest

  #if canImport(SwiftUI)
    import SwiftUI
  #endif

  final class CaseBindableTests: XCTestCase {
    func testCasePathableConformance() {
      let status = Status.inStock(quantity: 100)
      XCTAssertEqual(status[case: \.inStock], 100)
      XCTAssertNil(status[case: \.discontinued])
    }

    func testUIBindingEnumerationDerivesBinding() {
      @UIBinding var status = Status.inStock(quantity: 100)
      switch $status.cases {
      case .inStock(let quantity):
        XCTAssertEqual(quantity.wrappedValue, 100)
        quantity.wrappedValue = 42
      case .outOfStock, .onSale, .discontinued:
        XCTFail("Expected 'inStock'")
      }
      XCTAssertEqual(status, .inStock(quantity: 42))
    }

    func testUIBindingEnumerationLabeledAndCaselessCases() {
      @UIBinding var status = Status.outOfStock(isOnBackOrder: false)
      switch $status.cases {
      case .outOfStock(let isOnBackOrder):
        isOnBackOrder.wrappedValue = true
      case .inStock, .onSale, .discontinued:
        XCTFail("Expected 'outOfStock'")
      }
      XCTAssertEqual(status, .outOfStock(isOnBackOrder: true))

      status = .discontinued
      switch $status.cases {
      case .discontinued:
        break
      case .inStock, .outOfStock, .onSale:
        XCTFail("Expected 'discontinued'")
      }
    }

    func testUIBindingEnumerationMultipleAssociatedValues() {
      @UIBinding var status = Status.onSale(price: 100, discount: 10)
      switch $status.cases {
      case .onSale(let sale):
        XCTAssertEqual(sale.wrappedValue.price, 100)
        sale.wrappedValue.discount = 25
      case .inStock, .outOfStock, .discontinued:
        XCTFail("Expected 'onSale'")
      }
      XCTAssertEqual(status, .onSale(price: 100, discount: 25))
    }

    func testUIBindingChainsIntoCaseBindableMember() {
      @UIBinding var item = Item(name: "Widget", status: .inStock(quantity: 100))
      let name: UIBinding<String> = $item.name
      XCTAssertEqual(name.wrappedValue, "Widget")
      switch $item.status {
      case .inStock(let quantity):
        quantity.wrappedValue = 9
      case .outOfStock, .onSale, .discontinued:
        XCTFail("Expected 'inStock'")
      }
      XCTAssertEqual(item.status, .inStock(quantity: 9))
    }

    #if canImport(SwiftUI)
      @MainActor
      func testBindingEnumerationDerivesBinding() {
        let ref = Ref(status: .inStock(quantity: 100))
        let binding = Binding(get: { ref.status }, set: { ref.status = $0 })
        switch binding.cases {
        case .inStock(let quantity):
          XCTAssertEqual(quantity.wrappedValue, 100)
          quantity.wrappedValue = 7
        case .outOfStock, .discontinued, .onSale:
          XCTFail("Expected 'inStock'")
        }
        XCTAssertEqual(ref.status, .inStock(quantity: 7))
      }

      @MainActor
      func testBindingChainsIntoCaseBindableMember() {
        let ref = Ref(status: .inStock(quantity: 100))
        let item = Binding(
          get: { Item(name: "Widget", status: ref.status) },
          set: { ref.status = $0.status }
        )
        switch item.status {
        case .inStock(let quantity):
          quantity.wrappedValue = 3
        case .outOfStock, .onSale, .discontinued:
          XCTFail("Expected 'inStock'")
        }
        XCTAssertEqual(ref.status, .inStock(quantity: 3))
      }
    #endif
  }

  private struct Item {
    var name: String
    var status: Status
  }

  @CaseBindable
  private enum Status: Equatable {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)
    case onSale(price: Int, discount: Int)
    case discontinued
  }

  private final class Ref: @unchecked Sendable {
    var status: Status
    init(status: Status) { self.status = status }
  }
#endif
