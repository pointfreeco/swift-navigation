import SwiftUI

class AppViewModel: ObservableObject {
  @Published var inventoryViewModel: InventoryViewModel
  @Published var selectedTab: Tab

  init(
    inventoryViewModel: InventoryViewModel = .init(),
    selectedTab: Tab = .inventory
  ) {
    self.inventoryViewModel = inventoryViewModel
    self.selectedTab = selectedTab
  }

  enum Tab {
    case inventory
  }
}

@main
struct InventoryApp: App {
  @ObservedObject var viewModel = AppViewModel(
    inventoryViewModel: InventoryViewModel(
      inventory: [],
      route: .add(
        .init(
          name: "Keyboard",
          color: .blue,
          status: .outOfStock(isOnBackOrder: true)
        )
      )
    )
  )

  var body: some Scene {
    WindowGroup {
      TabView(selection: self.$viewModel.selectedTab) {
        NavigationView {
          InventoryView(viewModel: self.viewModel.inventoryViewModel)
            .tag(AppViewModel.Tab.inventory)
            .tabItem {
              Label("Inventory", systemImage: "building.2")
            }
        }
      }
    }
  }
}
