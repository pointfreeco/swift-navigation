import SwiftUI
import SwiftUINavigation

struct Item: Equatable, Identifiable {
  let id = UUID()
  var color: Color?
  var name: String
  var status: Status

  @CaseBindable
  enum Status: Equatable {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)
  }

  struct Color: Equatable, Hashable {
    var name: String
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0

    static let defaults: [Self] = [
      .red,
      .green,
      .blue,
      .black,
      .yellow,
      .white,
    ]

    static let red = Self(name: "Red", red: 1)
    static let green = Self(name: "Green", green: 1)
    static let blue = Self(name: "Blue", blue: 1)
    static let black = Self(name: "Black")
    static let yellow = Self(name: "Yellow", red: 1, green: 1)
    static let white = Self(name: "White", red: 1, green: 1, blue: 1)

    var swiftUIColor: SwiftUI.Color {
      SwiftUI.Color(red: red, green: green, blue: blue)
    }
  }
}

struct ItemView: View {
  @Binding var item: Item

  var body: some View {
    Form {
      TextField("Name", text: $item.name)

      Picker(selection: $item.color, label: Text("Color")) {
        Text("None")
          .tag(Item.Color?.none)

        ForEach(Item.Color.defaults, id: \.name) { color in
          Text(color.name)
            .tag(Optional(color))
        }
      }

      switch $item.status {
      case .inStock(let $quantity):
        Section {
          Stepper("Quantity: \($quantity.wrappedValue)", value: $quantity)
          Button("Mark as sold out") {
            withAnimation {
              item.status = .outOfStock(isOnBackOrder: false)
            }
          }
        } header: {
          Text("In stock")
        }
        .transition(.opacity)
      case .outOfStock(let $isOnBackOrder):
        Section {
          Toggle("Is on back order?", isOn: $isOnBackOrder)
          Button("Back in stock!") {
            withAnimation {
              item.status = .inStock(quantity: 1)
            }
          }
        } header: {
          Text("Out of stock")
        }
        .transition(.opacity)
      }
    }
  }
}

#Preview {
  @Previewable @State var item = Item(color: nil, name: "", status: .inStock(quantity: 1))
  ItemView(item: $item)
}
