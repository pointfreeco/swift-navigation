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

    By applying the `@CaseBindable` macro to the enum you can switch over a binding's cases \
    directly, and each case is handed a binding to its associated value.
    """

  @CaseBindable
  enum Status {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)
  }

  @State var status: Status = .inStock(quantity: 100)

  var body: some View {
    switch $status.cases {
    case .inStock(let $quantity):
      Section {
        Stepper("Quantity: \($quantity.wrappedValue)", value: $quantity)
        Button("Out of stock") {
          status = .outOfStock(isOnBackOrder: false)
        }
      } header: {
        Text("In stock")
      }
    case .outOfStock(let $isOnBackOrder):
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

#Preview {
  NavigationStack {
    CaseStudyView {
      EnumControls()
    }
  }
}
