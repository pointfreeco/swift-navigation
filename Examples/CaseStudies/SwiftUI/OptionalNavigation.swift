import SwiftUI
import SwiftUINavigation

struct OptionalNavigation: SwiftUICaseStudy {
  let caseStudyTitle = "Optional navigation"
  let readMe = """
    This case study demonstrates how to use powerful overloads of SwiftUI's presentation \
    modifiers, like `sheet(item:)`. These overloads not only allow you to forego `Identifiable` \
    conformances by instead providing a key path to an identifier, they also provide a _binding_ \
    to the data being presented rather than just plain data. This opens up a child-parent \
    communication “wormhole” that allows the child to write data directly back into the parent.
    """

  @State var alert: String?
  @State var drillDown: Int?
  @State var confirmationDialog: String?
  @State var fullScreenCover: Int?
  @State var popover: Int?
  @State var sheet: Int?

  var body: some View {
    Section {
      Button("Alert") {
        alert = "This is an alert!"
      }
      .alert(item: $alert) { title in
        Text(title)
      } actions: { _ in
      }

      Button("Confirmation dialog") {
        confirmationDialog = "This is a confirmation dialog!"
      }
      .alert(item: $confirmationDialog) { title in
        Text(title)
      } actions: { _ in
      }

      Button("Sheet") {
        sheet = .random(in: 1...1_000)
      }
      .sheet(item: $sheet, id: \.self) { $count in
        Form {
          Text(count.description)
          Button("Change count") {
            count = .random(in: 1...1_000)
          }
        }
        .navigationTitle("Sheet")
      }

      Button("Full-screen cover") {
        fullScreenCover = .random(in: 1...1_000)
      }
      .fullScreenCover(item: $fullScreenCover, id: \.self) { $count in
        NavigationStack {
          Form {
            Text(count.description)
            Button("Change count") {
              count = .random(in: 1...1_000)
            }
          }
          .navigationTitle("Full-screen cover")
          .toolbar {
            ToolbarItem {
              Button("Dismiss") {
                fullScreenCover = nil
              }
            }
          }
        }
      }

      Button("Popover") {
        popover = .random(in: 1...1_000)
      }
      .popover(item: $popover, id: \.self) { $count in
        Form {
          Text(count.description)
          Button("Change count") {
            count = .random(in: 1...1_000)
          }
        }
        .navigationTitle("Popover")
        .frame(idealWidth: 200, idealHeight: 160)
      }

      Button("Drill-down") {
        drillDown = .random(in: 1...1_000)
      }
      // NB: `navigationDestination` logs warning when applied directly in a "lazy" view like `Form`
      .background {
        EmptyView().navigationDestination(item: $drillDown) { $count in
          Form {
            Text(count.description)
            Button("Change count") {
              count = .random(in: 1...1_000)
            }
          }
          .navigationTitle("Drill-down")
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    CaseStudyView {
      OptionalNavigation()
    }
  }
}
