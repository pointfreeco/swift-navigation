import SwiftUI
import SwiftUINavigation

struct Item: Equatable, Identifiable {
  let id = UUID()
  var color: Color?
  var name: String
  var status: Status

  enum Status: Equatable {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)

    var isInStock: Bool {
      guard case .inStock = self else { return false }
      return true
    }
  }

  struct Color: Equatable, Hashable {
    var name: String
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0

    static var defaults: [Self] = [
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
      SwiftUI.Color(red: self.red, green: self.green, blue: self.blue)
    }
  }
}

struct ItemView: View {
  @Binding var item: Item

  var body: some View {
    Form {
      TextField("Name", text: self.$item.name)

      Picker(selection: self.$item.color, label: Text("Color")) {
        Text("None")
          .tag(Item.Color?.none)

        ForEach(Item.Color.defaults, id: \.name) { color in
          Text(color.name)
            .tag(Optional(color))
        }
      }

      Switch(self.$item.status) {
        CaseLet(/Item.Status.inStock) { $quantity in
          Section(header: Text("In stock")) {
            Stepper("Quantity: \(quantity)", value: $quantity)
            Button("Mark as sold out") {
              withAnimation {
                self.item.status = .outOfStock(isOnBackOrder: false)
              }
            }
          }
          .transition(.opacity)
        }
        CaseLet(/Item.Status.outOfStock) { $isOnBackOrder in
          Section(header: Text("Out of stock")) {
            Toggle("Is on back order?", isOn: $isOnBackOrder)
            Button("Is back in stock!") {
              withAnimation {
                self.item.status = .inStock(quantity: 1)
              }
            }
          }
          .transition(.opacity)
        }
      }
    }
  }
}

struct ItemView_Previews: PreviewProvider, View {
  @State var item = Item(color: nil, name: "", status: .inStock(quantity: 1))

  static var previews: some View {
    NavigationStack {
      ItemView_Previews()
    }
  }

  var body: some View {
    ItemView(item: self.$item)
  }
}
