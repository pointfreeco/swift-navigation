import IdentifiedCollections
import SwiftUINavigation

class InventoryViewModel: ObservableObject {
  @Published var inventory: IdentifiedArrayOf<ItemRowViewModel>
  @Published var route: Route?

  enum Route: Equatable {
    case add(Item)
    case row(id: ItemRowViewModel.ID, route: ItemRowViewModel.Route)
  }

  init(
    inventory: IdentifiedArrayOf<ItemRowViewModel> = [],
    route: Route? = nil
  ) {
    self.inventory = []
    self.route = route

    for itemRowViewModel in inventory {
      self.bind(itemRowViewModel: itemRowViewModel)
    }
  }

  func delete(item: Item) {
    withAnimation {
      _ = self.inventory.remove(id: item.id)
    }
  }

  func add(item: Item) {
    withAnimation {
      self.bind(itemRowViewModel: .init(item: item))
      self.route = nil
    }
  }

  func addButtonTapped() {
    self.route = .add(.init(name: "", color: nil, status: .inStock(quantity: 1)))

    Task { @MainActor in
      try await Task.sleep(nanoseconds: 500 * NSEC_PER_MSEC)
      try (/Route.add).modify(&self.route) {
        $0.name = "Bluetooth Keyboard"
      }
    }
  }

  func cancelButtonTapped() {
    self.route = nil
  }

  private func bind(itemRowViewModel: ItemRowViewModel) {
    itemRowViewModel.onDelete = { [weak self, item = itemRowViewModel.item] in
      withAnimation {
        self?.delete(item: item)
      }
    }

    itemRowViewModel.onDuplicate = { [weak self] item in
      withAnimation {
        self?.add(item: item)
      }
    }

    itemRowViewModel.$route
      .map { [id = itemRowViewModel.id] route in
        route.map { Route.row(id: id, route: $0) }
      }
      .removeDuplicates()
      .dropFirst()
      .assign(to: &self.$route)

    self.$route
      .map { [id = itemRowViewModel.id] route in
        guard
          case let .row(id: routeRowId, route: route) = route,
          routeRowId == id
        else { return nil }
        return route
      }
      .removeDuplicates()
      .assign(to: &itemRowViewModel.$route)

    self.inventory.append(itemRowViewModel)
  }
}

struct InventoryView: View {
  @ObservedObject var viewModel: InventoryViewModel

  var body: some View {
    List {
      ForEach(
        self.viewModel.inventory,
        content: ItemRowView.init(viewModel:)
      )
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Add") { self.viewModel.addButtonTapped() }
      }
    }
    .navigationTitle("Inventory")
    .sheet(unwrapping: self.$viewModel.route, case: /InventoryViewModel.Route.add) { $itemToAdd in
      NavigationView {
        ItemView(item: $itemToAdd)
          .navigationTitle("Add")
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") { self.viewModel.cancelButtonTapped() }
            }
            ToolbarItem(placement: .primaryAction) {
              Button("Save") { self.viewModel.add(item: itemToAdd) }
            }
          }
      }
    }
  }
}

struct InventoryView_Previews: PreviewProvider {
  static var previews: some View {
    let keyboard = Item(name: "Keyboard", color: .blue, status: .inStock(quantity: 100))

    NavigationView {
      InventoryView(
        viewModel: .init(
          inventory: [
            .init(item: keyboard),
            .init(item: Item(name: "Charger", color: .yellow, status: .inStock(quantity: 20))),
            .init(
              item: Item(name: "Phone", color: .green, status: .outOfStock(isOnBackOrder: true))),
            .init(
              item: Item(
                name: "Headphones", color: .green, status: .outOfStock(isOnBackOrder: false))),
          ],
          route: nil
        )
      )
    }
  }
}
