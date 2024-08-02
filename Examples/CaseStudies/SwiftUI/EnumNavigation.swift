import SwiftUI
import SwiftUINavigation

@CasePathable
enum Destination {
  case alert(String)
  case drillDown(Int)
  case confirmationDialog(String)
  case fullScreenCover(Int)
  case popover(Int)
  case sheet(Int)
  case sheetWithoutPayload
}

struct EnumNavigation: SwiftUICaseStudy {
  let caseStudyTitle = "Concise enum navigation"
  let caseStudyNavigationTitle = "Enum navigation"
  let readMe = """
    This case study builds upon the previous “optional navigation” case study to demonstrate how \
    to power multiple forms of navigation from a single destination enum that describes _all_ of \
    the possible destinations one can travel to from this screen.

    It includes a second sheet that contains no data in order to demonstrate how to transform a \
    binding of an optional to a binding of a Boolean.
    """

  @State var destination: Destination?

  var body: some View {
    Section {
      Button("Alert is presented: \(destination.is(\.alert) ? "✅" : "❌")") {
        destination = .alert("This is an alert!")
      }
      .alert(item: $destination.alert) { title in
        Text(title)
      } actions: { _ in
      }

      Button("Dialog is presented: \(destination.is(\.confirmationDialog) ? "✅" : "❌")") {
        destination = .confirmationDialog("This is a confirmation dialog!")
      }
      .alert(item: $destination.confirmationDialog) { title in
        Text(title)
      } actions: { _ in
      }

      Button("Sheet (with payload) is presented: \(destination.is(\.sheet) ? "✅" : "❌")") {
        destination = .sheet(.random(in: 1...1_000))
      }
      .sheet(item: $destination.sheet, id: \.self) { $count in
        Form {
          Text(count.description)
          Button("Change count") {
            count = .random(in: 1...1_000)
          }
        }
        .navigationTitle("Sheet")
        .presentationDetents([.medium])
      }

      Button(
        "Sheet (no payload) is presented: \(destination.is(\.sheetWithoutPayload) ? "✅" : "❌")"
      ) {
        destination = .sheetWithoutPayload
      }
      .sheet(isPresented: Binding($destination.sheetWithoutPayload)) {
        Form {
          Text("Hello!")
        }
        .navigationTitle("Sheet with payload")
        .presentationDetents([.medium])
      }

      Button("Cover is presented: \(destination.is(\.fullScreenCover) ? "✅" : "❌")") {
        destination = .fullScreenCover(.random(in: 1...1_000))
      }
      .fullScreenCover(item: $destination.fullScreenCover, id: \.self) { $count in
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
                destination = nil
              }
            }
          }
        }
      }

      Button("Popover is presented: \(destination.is(\.popover) ? "✅" : "❌")") {
        destination = .popover(.random(in: 1...1_000))
      }
      .popover(item: $destination.popover, id: \.self) { $count in
        Form {
          Text(count.description)
          Button("Change count") {
            count = .random(in: 1...1_000)
          }
        }
        .navigationTitle("Popover")
        .frame(idealWidth: 200, idealHeight: 160)
      }

      Button("Drill-down is presented: \(destination.is(\.drillDown) ? "✅" : "❌")") {
        destination = .drillDown(.random(in: 1...1_000))
      }
      // NB: `navigationDestination` logs warning when applied directly in a "lazy" view like `Form`
      .background {
        EmptyView().navigationDestination(item: $destination.drillDown) { $count in
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
      EnumNavigation()
    }
  }
}
