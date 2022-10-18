import SwiftUINavigation

private let readMe = """
  This case study demonstrates how to power multiple forms of navigation from a single route enum \
  that describes all of the possible destinations one can travel to from this screen.

  The screen has three navigation destinations: an alert, a navigation link to a count stepper, \
  and a modal sheet to a count stepper. The state for each of these destinations is held as \
  associated data of an enum, and bindings to the cases of that enum are derived using \
  the tools in this library.
  """

enum Route {
  case alert(String)
  case link(Int)
  case sheet(Int)
}

struct Routing: View {
  @State var route: Route?

  var body: some View {
    Form {
      Section {
        Text(readMe)
      }

      Button("Alert") {
        self.route = .alert("Hello world!")
      }
      .alert(
        title: { Text($0) },
        unwrapping: self.$route,
        case: /Route.alert,
        actions: { _ in
          Button("Activate link") {
            self.route = .link(0)
          }
          Button("Activate sheet") {
            self.route = .sheet(0)
          }
          Button("Cancel", role: .cancel) {
          }
        },
        message: { _ in

        }
      )

      NavigationLink(unwrapping: self.$route, case: /Route.link) {
        self.route = $0 ? .link(0) : nil
      } destination: { $count in
        Form {
          Stepper("Number: \(count)", value: $count)
        }
      } label: {
        Text("Link")
      }

      Button("Sheet") {
        self.route = .sheet(0)
      }
      .sheet(
        unwrapping: self.$route,
        case: /Route.sheet
      ) { $count in
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
