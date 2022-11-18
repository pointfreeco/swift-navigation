import SwiftUI
import SwiftUINavigation

private let readMe = """
  This case study demonstrates how to power multiple forms of navigation from a single destination \
  enum that describes all of the possible destinations one can travel to from this screen.

  The screen has three navigation destinations: an alert, a navigation link to a count stepper, \
  and a modal sheet to a count stepper. The state for each of these destinations is held as \
  associated data of an enum, and bindings to the cases of that enum are derived using the tools \
  in this library.
  """

enum Destination {
  case alert(AlertState<Never>)
  case confirmationDialog(ConfirmationDialogState<Never>)
  case link(Int)
  case sheet(Int)
}

struct Routing: View {
  @State var destination: Destination?

  var body: some View {
    Form {
      Section {
        Text(readMe)
      }

      Button("Alert") {
        self.destination = .alert(AlertState { TextState("Hello world!") })
      }
      .alert(unwrapping: self.$destination, case: /Destination.alert)

      Button("Confirmation dialog") {
        self.destination = .confirmationDialog(
          ConfirmationDialogState(
            title: TextState("Hello world!"),
            titleVisibility: .visible 
          )
        )
      }
      .confirmationDialog(unwrapping: self.$destination, case: /Destination.confirmationDialog)

      NavigationLink(unwrapping: self.$destination, case: /Destination.link) {
        self.destination = $0 ? .link(0) : nil
      } destination: { $count in
        Form {
          Stepper("Number: \(count)", value: $count)
        }
        .navigationTitle("Routing link")
      } label: {
        Text("Link")
      }

      Button("Sheet") {
        self.destination = .sheet(0)
      }
      .sheet(unwrapping: self.$destination, case: /Destination.sheet) { $count in
        Form {
          Stepper("Number: \(count)", value: $count)
        }
      }
    }
    .navigationTitle("Routing")
  }
}

struct Routing_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      Routing()
    }
  }
}
