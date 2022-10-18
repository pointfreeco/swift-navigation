import SwiftUINavigation

class ItemRowViewModel: Identifiable, ObservableObject {
  @Published var item: Item
  @Published var route: Route?

  enum Route: Equatable {
    case deleteAlert
    case duplicate(Item)
    case edit(Item)
  }

  var onDelete: () -> Void = {}
  var onDuplicate: (Item) -> Void = { _ in }

  var id: Item.ID { self.item.id }

  init(
    item: Item
  ) {
    self.item = item
  }

  func deleteButtonTapped() {
    self.route = .deleteAlert
  }

  func deleteConfirmationButtonTapped() {
    self.onDelete()
  }

  func setEditNavigation(isActive: Bool) {
    self.route = isActive ? .edit(self.item) : nil
  }

  func edit(item: Item) {
    self.item = item
    self.route = nil
  }

  func cancelButtonTapped() {
    self.route = nil
  }

  func duplicateButtonTapped() {
    self.route = .duplicate(self.item.duplicate())
  }

  func duplicate(item: Item) {
    self.onDuplicate(item)
    self.route = nil
  }
}

extension Item {
  func duplicate() -> Self {
    .init(name: self.name, color: self.color, status: self.status)
  }
}

struct ItemRowView: View {
  @ObservedObject var viewModel: ItemRowViewModel

  var body: some View {
    NavigationLink(unwrapping: self.$viewModel.route, case: /ItemRowViewModel.Route.edit) {
      self.viewModel.setEditNavigation(isActive: $0)
    } destination: { $item in
      ItemView(item: $item)
        .navigationBarTitle("Edit")
        .navigationBarBackButtonHidden(true)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              self.viewModel.cancelButtonTapped()
            }
          }
          ToolbarItem(placement: .primaryAction) {
            Button("Save") {
              self.viewModel.edit(item: item)
            }
          }
        }
    } label: {
      HStack {
        VStack(alignment: .leading) {
          Text(self.viewModel.item.name)

          switch self.viewModel.item.status {
          case let .inStock(quantity):
            Text("In stock: \(quantity)")
          case let .outOfStock(isOnBackOrder):
            Text("Out of stock\(isOnBackOrder ? ": on back order" : "")")
          }
        }

        Spacer()

        if let color = self.viewModel.item.color {
          Rectangle()
            .frame(width: 30, height: 30)
            .foregroundColor(color.swiftUIColor)
            .border(Color.black, width: 1)
        }

        Button(action: { self.viewModel.duplicateButtonTapped() }) {
          Image(systemName: "square.fill.on.square.fill")
        }
        .padding(.leading)

        Button(action: { self.viewModel.deleteButtonTapped() }) {
          Image(systemName: "trash.fill")
        }
        .padding(.leading)
      }
      .buttonStyle(.plain)
      .foregroundColor(self.viewModel.item.status.isInStock ? nil : Color.gray)
      .alert(
        title: { Text(self.viewModel.item.name) },
        unwrapping: self.$viewModel.route,
        case: /ItemRowViewModel.Route.deleteAlert,
        actions: {
          Button("Delete", role: .destructive) {
            self.viewModel.deleteConfirmationButtonTapped()
          }
        },
        message: {
          Text("Are you sure you want to delete this item?")
        }
      )
      .popover(
        unwrapping: self.$viewModel.route,
        case: /ItemRowViewModel.Route.duplicate
      ) { $item in
        NavigationView {
          ItemView(item: $item)
            .navigationBarTitle("Duplicate")
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                  self.viewModel.cancelButtonTapped()
                }
              }
              ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                  self.viewModel.duplicate(item: item)
                }
              }
            }
        }
        .frame(minWidth: 300, minHeight: 500)
      }
    }
  }
}
