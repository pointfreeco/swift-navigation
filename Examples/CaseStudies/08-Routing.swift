import SwiftUI
import SwiftUINavigation

private let readMe = """
  This case study demonstrates how to power multiple forms of navigation from a single destination \
  enum that describes all of the possible destinations one can travel to from this screen.

  The screen has four navigation destinations: an alert, a confirmation dialog, a navigation link \
  to a count stepper, and a modal sheet to a count stepper. The state for each of these \
  destinations is held as associated data of an enum, and bindings to the cases of that enum are \
  derived using the tools in this library.
  """

@CasePathable
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
        Text("Count: \(count)")
      }

      Button("Alert") {
        destination = .alert(
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
        destination = .confirmationDialog(
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

      Button("Link") {
        destination = .link(count)
      }

      Button("Sheet") {
        destination = .sheet(count)
      }
    }
    .navigationTitle("Routing")
    .alert($destination.alert) { action in
      switch action {
      case .randomize?:
        count = .random(in: 0...1_000)
      case .reset?:
        count = 0
      case nil:
        break
      }
    }
    .confirmationDialog($destination.confirmationDialog) { action in
      switch action {
      case .decrement?:
        count -= 1
      case .increment?:
        count += 1
      case nil:
        break
      }
    }
    .navigationDestination(item: $destination.link) { $count in
      Form {
        Stepper("Count: \(count)", value: $count)
      }
      .navigationTitle("Routing link")
    }
    .sheet(item: $destination.sheet, id: \.self) { $count in
      NavigationStack {
        Form {
          Stepper("Count: \(count)", value: $count)
        }
        .navigationTitle("Routing sheet")
      }
    }
  }
}

#Preview {
  NavigationStack {
    Routing()
  }
}
