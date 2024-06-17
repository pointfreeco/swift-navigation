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
    This case study demonstrates how to power multiple forms of navigation from a single \
    destination enum that describes all of the possible destinations one can travel to from this \
    screen.
    
    The screen has four possible destinations: an alert, a confirmation dialog, and two kinds \
    of sheets. The state for each of these destinations is held as associated data of an enum, and \
    bindings to the cases of that enum are derived using the tools in this library.
    """

  @State var destination: Destination?
  
  var body: some View {
    Section {
      Button("Alert") {
        destination = .alert("This is an alert!")
      }
      .alert(item: $destination.alert) { title in
        Text(title)
      } actions: { _ in
      }

      Button("Confirmation dialog") {
        destination = .confirmationDialog("This is a confirmation dialog!")
      }
      .alert(item: $destination.confirmationDialog) { title in
        Text(title)
      } actions: { _ in
      }

      Button("Sheet (with payload)") {
        destination = .sheet(.random(in: 1...1_000))
      }
      .sheet(item: $destination.sheet, id: \.self) { $count in
        Form {
          Text(count.description)
          Button("Change count") {
            count = .random(in: 1...1_000)
          }
        }
        .navigationTitle("Sheet with payload")
      }

      Button("Sheet (without payload)") {
        destination = .sheetWithoutPayload
      }
      .sheet(isPresented: Binding($destination.sheetWithoutPayload)) {
        Form {
          Text("Hello!")
        }
        .navigationTitle("Sheet with payload")
      }

      Button("Full-screen cover") {
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

      Button("Popover") {
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

      Button("Drill-down") {
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
