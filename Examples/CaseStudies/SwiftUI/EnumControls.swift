import SwiftUI
import SwiftUINavigation

struct EnumControls: SwiftUICaseStudy, View {
  let caseStudyTitle = "Concise enum controls"
  let caseStudyNavigationTitle = "Enum controls"
  let readMe = """
    This case study demonstrates how to drive form controls from bindings to enum state. In this \
    example, a single `Status` enum holds two cases:

    • An integer quantity for when an item is in stock, which can drive a stepper.
    • A Boolean for whether an item is on back order when it is _not_ in stock, which can drive a \
    toggle.

    This library provides tools to chain deeper into a binding's case by applying the \
    `@CasePathable` macro.
    """

  @CasePathable
  enum Status {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)
  }

  @State var status: Status = .inStock(quantity: 100)

  var body: some View {
    switch status {
    case .inStock:
      $status.inStock.map { $quantity in
        Section {
          Stepper("Quantity: \(quantity)", value: $quantity)
          Button("Out of stock") {
            status = .outOfStock(isOnBackOrder: false)
          }
        } header: {
          Text("In stock")
        }
      }
    case .outOfStock:
      $status.outOfStock.map { $isOnBackOrder in
        Section {
          Toggle("Is on back order?", isOn: $isOnBackOrder)
          Button("Back in stock!") {
            status = .inStock(quantity: 100)
          }
        } header: {
          Text("Out of stock")
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    CaseStudyView {
      EnumControls()
    }
  }
}
