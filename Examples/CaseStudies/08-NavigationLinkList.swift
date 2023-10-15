import SwiftUI
import SwiftUINavigation

private let readMe = """
  This case study demonstrates how to model a list of navigation links. Tap a row to drill down \
  and edit a counter. Edit screen allows cancelling or saving the edits.

  The domain for a row in the list has its own @Observable class and Destination enum, and it uses \
  the library's NavigationLink initializer to drive navigation from the destination enum.
  """

struct ListOfNavigationLinks: View {
  @State var model: ListOfNavigationLinksModel

  var body: some View {
    Form {
      Section {
        Text(readMe)
      }

      List {
        ForEach(self.model.rows) { rowModel in
          RowView(model: rowModel)
        }
        .onDelete(perform: self.model.deleteButtonTapped(indexSet:))
      }
    }
    .navigationTitle("List of links")
    .toolbar {
      ToolbarItem {
        Button("Add") {
          self.model.addButtonTapped()
        }
      }
    }
  }
}

@Observable
class ListOfNavigationLinksModel {
  var rows: [ListOfNavigationLinksRowModel]

  init(rows: [ListOfNavigationLinksRowModel] = []) {
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

private struct RowView: View {
  @State var model: ListOfNavigationLinksRowModel

  var body: some View {
    NavigationLink(
      unwrapping: self.$model.destination,
      case: /ListOfNavigationLinksRowModel.Destination.edit
    ) { isActive in
      self.model.setEditNavigation(isActive: isActive)
    } destination: { $counter in
      EditView(counter: $counter)
        .navigationBarBackButtonHidden(true)
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Save") { self.model.saveButtonTapped(counter: counter) }
          }
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { self.model.cancelButtonTapped() }
          }
        }
    } label: {
      Text("\(self.model.counter)")
    }
  }
}

@Observable
class ListOfNavigationLinksRowModel: Identifiable {
  let id = UUID()
  var counter: Int
  var destination: Destination?

  enum Destination {
    case edit(Int)
  }

  init(
    counter: Int = 0,
    destination: Destination? = nil
  ) {
    self.counter = counter
    self.destination = destination
  }

  func setEditNavigation(isActive: Bool) {
    self.destination = isActive ? .edit(self.counter) : nil
  }

  func saveButtonTapped(counter: Int) {
    self.counter = counter
    self.destination = nil
  }

  func cancelButtonTapped() {
    self.destination = nil
  }
}

private struct EditView: View {
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

#Preview {
  NavigationView {
    ListOfNavigationLinks(
      model: ListOfNavigationLinksModel(
        rows: [
          ListOfNavigationLinksRowModel(counter: 0),
          ListOfNavigationLinksRowModel(counter: 0),
          ListOfNavigationLinksRowModel(counter: 0),
          ListOfNavigationLinksRowModel(counter: 0),
          ListOfNavigationLinksRowModel(counter: 0),
        ]
      )
    )
  }
}
