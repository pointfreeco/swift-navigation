import SwiftUI
import SwiftUINavigation
import XCTestDynamicOverlay

@Observable
class ItemRowModel: Identifiable {
  var item: Item
  var destination: Destination?

  @CasePathable
  enum Destination: Equatable {
    case alert(AlertState<AlertAction>)
    case duplicate(Item)
  }

  enum AlertAction {
    case deleteConfirmation
  }

  var onDelete: () -> Void = unimplemented("ItemRowModel.onDelete")
  var onDuplicate: (Item) -> Void = unimplemented("ItemRowModel.onDuplicate")
  var onTap: () -> Void = unimplemented("ItemRowModel.onTap")

  var id: Item.ID { item.id }

  init(item: Item) {
    self.item = item
  }

  func deleteButtonTapped() {
    destination = .alert(
      AlertState {
        TextState(item.name)
      } actions: {
        ButtonState(role: .destructive, action: .send(.deleteConfirmation, animation: .default)) {
          TextState("Delete")
        }
      } message: {
        TextState("Are you sure you want to delete this item?")
      }
    )
  }

  func alertButtonTapped(_ action: AlertAction?) {
    switch action {
    case .deleteConfirmation?:
      onDelete()
    case nil:
      break
    }
  }

  func cancelButtonTapped() {
    destination = nil
  }

  func duplicateButtonTapped() {
    destination = .duplicate(item.duplicate())
  }

  func duplicate(item: Item) {
    onDuplicate(item)
    destination = nil
  }

  func rowTapped() {
    onTap()
  }
}

extension Item {
  func duplicate() -> Self {
    Self(color: color, name: name, status: status)
  }
}

struct ItemRowView: View {
  @State var model: ItemRowModel

  var body: some View {
    Button {
      model.rowTapped()
    } label: {
      HStack {
        VStack(alignment: .leading) {
          Text(model.item.name)
            .font(.title3)

          switch model.item.status {
          case let .inStock(quantity):
            Text("In stock: \(quantity)")
          case let .outOfStock(isOnBackOrder):
            Text("Out of stock\(isOnBackOrder ? ": on back order" : "")")
          }
        }

        Spacer()

        if let color = model.item.color {
          Rectangle()
            .frame(width: 30, height: 30)
            .foregroundColor(color.swiftUIColor)
            .border(Color.black, width: 1)
        }

        Button(action: { model.duplicateButtonTapped() }) {
          Image(systemName: "square.fill.on.square.fill")
        }
        .padding(.leading)

        Button(action: { model.deleteButtonTapped() }) {
          Image(systemName: "trash.fill")
        }
        .padding(.leading)
      }
      .buttonStyle(.plain)
      .foregroundColor(model.item.status.is(\.inStock) ? nil : Color.gray)
      .alert($model.destination.alert) {
        model.alertButtonTapped($0)
      }
      .popover(item: $model.destination.duplicate) { $item in
        NavigationStack {
          ItemView(item: $item)
            .navigationBarTitle("Duplicate")
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                  model.cancelButtonTapped()
                }
              }
              ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                  model.duplicate(item: item)
                }
              }
            }
        }
        .frame(minWidth: 300, minHeight: 500)
      }
    }
  }
}

#Preview {
  List {
    ItemRowView(
      model: ItemRowModel(
        item: Item(
          name: "Keyboard",
          status: .inStock(quantity: 42)
        )
      )
    )
  }
}
