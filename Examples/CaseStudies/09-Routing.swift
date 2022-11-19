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
  case alert(AlertState<AlertAction>)
  case confirmationDialog(ConfirmationDialogState<DialogAction>)
  case link(Int)
  case sheet(Int)

  enum AlertAction {
    case randomize
    case reset
  }
  enum DialogAction {
    case decrement
    case increment
  }
}

struct Routing: View {
  @State var count = 0
  @State var destination: Destination?

  var body: some View {
    Form {
      Section {
        Text(readMe)
      }

      Section {
        Text("Count: \(self.count)")
      }

      Button("Alert") {
        self.destination = .alert(
          AlertState {
            TextState("Update count?")
          } actions: {
            ButtonState(action: .send(.randomize)) {
              TextState("Randomize")
            }
            ButtonState(role: .destructive, action: .send(.reset)) {
              TextState("Reset")
            }
          }
        )
      }

      Button("Confirmation dialog") {
        self.destination = .confirmationDialog(
          ConfirmationDialogState(titleVisibility: .visible) {
            TextState("Update count?")
          } actions: {
            ButtonState(action: .send(.increment)) {
              TextState("Increment")
            }
            ButtonState(action: .send(.decrement)) {
              TextState("Decrement")
            }
          }
        )
      }

      NavigationLink(unwrapping: self.$destination, case: /Destination.link) { isActive in
        if isActive {
          self.destination = .link(self.count)
        }
      } destination: { $count in
        Form {
          Stepper("Number: \(count)", value: $count)
        }
        .navigationTitle("Routing link")
      } label: {
        Text("Link")
      }

      Button("Sheet") {
        self.destination = .sheet(self.count)
      }
    }
    .navigationTitle("Routing")
    .alert(unwrapping: self.$destination, case: /Destination.alert) { action in
      switch action {
      case .randomize:
        self.count = .random(in: 0...1_000)
      case .reset:
        self.count = 0
      }
    }
    .confirmationDialog(
      unwrapping: self.$destination,
      case: /Destination.confirmationDialog
    ) { action in
      switch action {
      case .decrement:
        self.count -= 1
      case .increment:
        self.count += 1
      }
    }
    .sheet(unwrapping: self.$destination, case: /Destination.sheet) { $count in
      NavigationView {
        Form {
          Stepper("Number: \(count)", value: $count)
        }
        .navigationTitle("Routing sheet")
      }
    }
  }
}

struct Routing_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      Routing()
    }
  }
}
