import IdentifiedCollections
import SwiftUI
import SwiftUINavigation

class InventoryModel: ObservableObject {
  @Published var inventory: IdentifiedArrayOf<ItemRowModel> {
    didSet { self.bind() }
  }
  @Published var destination: Destination?

  enum Destination: Equatable {
    case add(Item)
    case edit(Item)
  }

  init(
    inventory: IdentifiedArrayOf<ItemRowModel> = [],
    route: Destination? = nil
  ) {
    self.inventory = inventory
    self.destination = route
    self.bind()
  }

  func delete(item: Item) {
    withAnimation {
      _ = self.inventory.remove(id: item.id)
    }
  }

  func add(item: Item) {
    withAnimation {
      self.inventory.append(ItemRowModel(item: item))
      self.destination = nil
    }
  }

  func addButtonTapped() {
    self.destination = .add(.init(color: nil, name: "", status: .inStock(quantity: 1)))
  }

  func cancelButtonTapped() {
    self.destination = nil
  }

  func cancelEditButtonTapped() {
    self.destination = nil
  }

  func commitEdit(item: Item) {
    self.inventory[id: item.id]?.item = item
    self.destination = nil
  }

  private func bind() {
    for itemRowModel in self.inventory {
      itemRowModel.onDelete = { [weak self, weak itemRowModel] in
        guard let self, let itemRowModel else { return }
        withAnimation {
          self.delete(item: itemRowModel.item)
        }
      }
      itemRowModel.onDuplicate = { [weak self] item in
        guard let self else { return }
        withAnimation {
          self.add(item: item)
        }
      }
      itemRowModel.onTap = { [weak self, weak itemRowModel] in
        guard let self, let itemRowModel else { return }
        self.destination = .edit(itemRowModel.item)
      }
    }
  }
}

struct InventoryView: View {
  @ObservedObject var model: InventoryModel

  var body: some View {
    List {
      ForEach(
        self.model.inventory,
        content: ItemRowView.init(model:)
      )
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Add") { self.model.addButtonTapped() }
      }
    }
    .navigationTitle("Inventory")
    .navigationDestination(
      unwrapping: self.$model.destination,
      case: /InventoryModel.Destination.edit
    ) { $item in
      ItemView(item: $item)
        .navigationBarTitle("Edit")
        .navigationBarBackButtonHidden(true)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              self.model.cancelEditButtonTapped()
            }
          }
          ToolbarItem(placement: .primaryAction) {
            Button("Save") {
              self.model.commitEdit(item: item)
            }
          }
        }
    }
    .sheet(
      unwrapping: self.$model.destination,
      case: /InventoryModel.Destination.add
    ) { $itemToAdd in
      NavigationStack {
        ItemView(item: $itemToAdd)
          .navigationTitle("Add")
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") { self.model.cancelButtonTapped() }
            }
            ToolbarItem(placement: .primaryAction) {
              Button("Save") { self.model.add(item: itemToAdd) }
            }
          }
      }
    }
  }
}

struct InventoryView_Previews: PreviewProvider {
  static var previews: some View {
    let keyboard = Item(color: .blue, name: "Keyboard", status: .inStock(quantity: 100))

    NavigationStack {
      InventoryView(
         model: .init(
          inventory: [
            .init(item: keyboard),
            .init(item: Item(color: .yellow, name: "Charger", status: .inStock(quantity: 20))),
            .init(
              item: Item(color: .green, name: "Phone", status: .outOfStock(isOnBackOrder: true))),
            .init(
              item: Item(
                color: .green, name: "Headphones", status: .outOfStock(isOnBackOrder: false))),
          ],
          route: nil
        )
      )
    }
  }
}
