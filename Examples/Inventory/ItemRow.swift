import SwiftUI
import SwiftUINavigation
import XCTestDynamicOverlay

class ItemRowModel: Identifiable, ObservableObject {
  @Published var item: Item
  @Published var destination: Destination?

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

  var id: Item.ID { self.item.id }

  init(item: Item) {
    self.item = item
  }

  func deleteButtonTapped() {
    self.destination = .alert(
      AlertState {
        TextState(self.item.name)
      } actions: {
        ButtonState(role: .destructive, action: .send(.deleteConfirmation, animation: .default)) {
          TextState("Delete")
        }
      } message: {
        TextState("Are you sure you want to delete this item?")
      }
    )
  }

  func alertButtonTapped(_ action: AlertAction) {
    switch action {
    case .deleteConfirmation:
      self.onDelete()
    }
  }

  func cancelButtonTapped() {
    self.destination = nil
  }

  func duplicateButtonTapped() {
    self.destination = .duplicate(self.item.duplicate())
  }

  func duplicate(item: Item) {
    self.onDuplicate(item)
    self.destination = nil
  }

  func rowTapped() {
    self.onTap()
  }
}

extension Item {
  func duplicate() -> Self {
    Self(color: self.color, name: self.name, status: self.status)
  }
}

struct ItemRowView: View {
  @ObservedObject var model: ItemRowModel

  var body: some View {
    Button {
      self.model.rowTapped()
    } label: {
      HStack {
        VStack(alignment: .leading) {
          Text(self.model.item.name)
            .font(.title3)

          switch self.model.item.status {
          case let .inStock(quantity):
            Text("In stock: \(quantity)")
          case let .outOfStock(isOnBackOrder):
            Text("Out of stock\(isOnBackOrder ? ": on back order" : "")")
          }
        }

        Spacer()

        if let color = self.model.item.color {
          Rectangle()
            .frame(width: 30, height: 30)
            .foregroundColor(color.swiftUIColor)
            .border(Color.black, width: 1)
        }

        Button(action: { self.model.duplicateButtonTapped() }) {
          Image(systemName: "square.fill.on.square.fill")
        }
        .padding(.leading)

        Button(action: { self.model.deleteButtonTapped() }) {
          Image(systemName: "trash.fill")
        }
        .padding(.leading)
      }
      .buttonStyle(.plain)
      .foregroundColor(self.model.item.status.isInStock ? nil : Color.gray)
      .alert(
        unwrapping: self.$model.destination,
        case: /ItemRowModel.Destination.alert,
        action: self.model.alertButtonTapped
      )
      .popover(
        unwrapping: self.$model.destination,
        case: /ItemRowModel.Destination.duplicate
      ) { $item in
        NavigationStack {
          ItemView(item: $item)
            .navigationBarTitle("Duplicate")
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                  self.model.cancelButtonTapped()
                }
              }
              ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                  self.model.duplicate(item: item)
                }
              }
            }
        }
        .frame(minWidth: 300, minHeight: 500)
      }
    }
  }
}
