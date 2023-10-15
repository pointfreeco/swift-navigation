import SwiftUI

@main
struct InventoryApp: App {
  let model = AppModel(
    inventoryModel: InventoryModel(
      inventory: [
        ItemRowModel(
          item: Item(color: .red, name: "Keyboard", status: .inStock(quantity: 100))
        ),
        ItemRowModel(
          item: Item(color: .blue, name: "Mouse", status: .inStock(quantity: 200))
        ),
        ItemRowModel(
          item: Item(color: .green, name: "Monitor", status: .inStock(quantity: 20))
        ),
        ItemRowModel(
          item: Item(color: .yellow, name: "Chair", status: .outOfStock(isOnBackOrder: true))
        ),
      ]
    )
  )

  var body: some Scene {
    WindowGroup {
      AppView(model: self.model)
    }
  }
}

@Observable
class AppModel {
  var inventoryModel: InventoryModel
  var selectedTab: Tab

  init(
    inventoryModel: InventoryModel,
    selectedTab: Tab = .first
  ) {
    self.inventoryModel = inventoryModel
    self.selectedTab = selectedTab
  }

  enum Tab {
    case first
    case inventory
  }
}

struct AppView: View {
  @State var model: AppModel

  var body: some View {
    TabView(selection: self.$model.selectedTab) {
      Button {
        self.model.selectedTab = .inventory
      } label: {
        Text("Go to inventory tab")
      }
      .tag(AppModel.Tab.first)
      .tabItem {
        Label("First", systemImage: "arrow.forward")
      }

      NavigationStack {
        InventoryView(model: self.model.inventoryModel)
      }
      .tag(AppModel.Tab.inventory)
      .tabItem {
        Label("Inventory", systemImage: "list.clipboard.fill")
      }
    }
  }
}

#Preview {
  AppView(model: AppModel(inventoryModel: InventoryModel()))
}
