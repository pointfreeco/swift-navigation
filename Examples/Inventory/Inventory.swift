import IdentifiedCollections
import SwiftUI
import SwiftUINavigation

@Observable
class InventoryModel {
  var inventory: IdentifiedArrayOf<ItemRowModel> {
    didSet { bind() }
  }
  var destination: Destination?

  @CasePathable
  enum Destination: Equatable {
    case add(Item)
    case edit(Item)
  }

  init(
    inventory: IdentifiedArrayOf<ItemRowModel> = [],
    destination: Destination? = nil
  ) {
    self.inventory = inventory
    self.destination = destination
    self.bind()
  }

  func delete(item: Item) {
    _ = inventory.remove(id: item.id)
  }

  func add(item: Item) {
    withAnimation {
      inventory.append(ItemRowModel(item: item))
      destination = nil
    }
  }

  func addButtonTapped() {
    destination = .add(Item(color: nil, name: "", status: .inStock(quantity: 1)))
  }

  func cancelButtonTapped() {
    destination = nil
  }

  func cancelEditButtonTapped() {
    destination = nil
  }

  func commitEdit(item: Item) {
    inventory[id: item.id]?.item = item
    destination = nil
  }

  private func bind() {
    for itemRowModel in inventory {
      itemRowModel.onDelete = { [weak self, weak itemRowModel] in
        guard let self, let itemRowModel else { return }
        delete(item: itemRowModel.item)
      }
      itemRowModel.onDuplicate = { [weak self] item in
        guard let self else { return }
        add(item: item)
      }
      itemRowModel.onTap = { [weak self, weak itemRowModel] in
        guard let self, let itemRowModel else { return }
        destination = .edit(itemRowModel.item)
      }
    }
  }
}

struct InventoryView: View {
  @State var model: InventoryModel

  var body: some View {
    List {
      ForEach(model.inventory) {
        ItemRowView(model: $0)
      }
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Add") { model.addButtonTapped() }
      }
    }
    .navigationTitle("Inventory")
    .navigationDestination(item: $model.destination.edit) { $item in
      ItemView(item: $item)
        .navigationBarTitle("Edit")
        .navigationBarBackButtonHidden(true)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              model.cancelEditButtonTapped()
            }
          }
          ToolbarItem(placement: .primaryAction) {
            Button("Save") {
              model.commitEdit(item: item)
            }
          }
        }
    }
    .sheet(item: $model.destination.add) { $itemToAdd in
      NavigationStack {
        ItemView(item: $itemToAdd)
          .navigationTitle("Add")
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") { model.cancelButtonTapped() }
            }
            ToolbarItem(placement: .primaryAction) {
              Button("Save") { model.add(item: itemToAdd) }
            }
          }
      }
    }
  }
}

#Preview {
  let keyboard = Item(
    color: .blue,
    name: "Keyboard",
    status: .inStock(quantity: 100)
  )

  return NavigationStack {
    InventoryView(
      model: InventoryModel(
        inventory: [
          ItemRowModel(
            item: keyboard
          ),
          ItemRowModel(
            item: Item(color: .yellow, name: "Charger", status: .inStock(quantity: 20))
          ),
          ItemRowModel(
            item: Item(color: .green, name: "Phone", status: .outOfStock(isOnBackOrder: true))
          ),
          ItemRowModel(
            item: Item(
              color: .green, name: "Headphones", status: .outOfStock(isOnBackOrder: false)
            )
          ),
        ]
      )
    )
  }
}
