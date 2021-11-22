import SwiftUI
import SwiftUINavigation

private let readMe = """
This case study demonstrates how to model a list of navigation links. Tap a row to drill down and edit a counter. Edit screen allows cancelling or saving the edits.

The domain for a row in the list has its own ObservableObject and Route enum, and it uses the library's NavigationLink initializer to drive navigation from the route enum.
"""

struct ListOfNavigationLinks: View {
  @ObservedObject var viewModel: ListOfNavigationLinksViewModel

  var body: some View {
    Form {
      Section {
        Text(readMe)
      }

      List {
        ForEach(self.viewModel.rows) { rowViewModel in
          RowView(viewModel: rowViewModel)
        }
        .onDelete(perform: self.viewModel.deleteButtonTapped(indexSet:))
      }
    }
    .navigationTitle("List of Links")
    .toolbar {
      ToolbarItem {
        Button("Add") {
          self.viewModel.addButtonTapped()
        }
      }
    }
  }
}

class ListOfNavigationLinksViewModel: ObservableObject {
  @Published var rows: [ListOfNavigationLinksRowViewModel]

  init(rows: [ListOfNavigationLinksRowViewModel] = []) {
    self.rows = rows
  }

  func addButtonTapped() {
    withAnimation {
      self.rows.append(.init())
    }
  }

  func deleteButtonTapped(indexSet: IndexSet) {
    self.rows.remove(atOffsets: indexSet)
  }
}

fileprivate struct RowView: View {
  @ObservedObject var viewModel: ListOfNavigationLinksRowViewModel

  var body: some View {
    NavigationLink(unwrapping: self.$viewModel.route, case: /ListOfNavigationLinksRowViewModel.Route.edit) { $counter in
      EditView(counter: $counter)
        .navigationBarBackButtonHidden(true)
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Save") { self.viewModel.saveButtonTapped(counter: counter) }
          }
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { self.viewModel.cancelButtonTapped() }
          }
        }
    } onNavigate: {
      self.viewModel.setEditNavigation(isActive: $0)
    } label: {
      Text("\(self.viewModel.counter)")
    }
  }
}

class ListOfNavigationLinksRowViewModel: Identifiable, ObservableObject {
  let id = UUID()
  @Published var counter: Int
  @Published var route: Route?

  enum Route {
    case edit(Int)
  }

  init(
    counter: Int = 0,
    route: Route? = nil
  ) {
    self.counter = counter
    self.route = route
  }

  func setEditNavigation(isActive: Bool) {
    self.route = isActive ? .edit(self.counter) : nil
  }

  func saveButtonTapped(counter: Int) {
    self.counter = counter
    self.route = nil
  }

  func cancelButtonTapped() {
    self.route = nil
  }
}

fileprivate struct EditView: View {
  @Binding var counter: Int

  var body: some View {
    Form {
      Text("Count: \(self.counter)")
      Button("Increment") {
        self.counter += 1
      }
      Button("Decrement") {
        self.counter -= 1
      }
    }
  }
}

struct ListOfNavigationLinks_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      ListOfNavigationLinks(
        viewModel: .init(
          rows: [
            .init(counter: 0),
            .init(counter: 0),
            .init(counter: 0),
            .init(counter: 0),
            .init(counter: 0),
          ]
        )
      )
    }
  }
}
