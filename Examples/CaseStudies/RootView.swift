import SwiftUI
import SwiftUINavigation

struct RootView: View {
  var body: some View {
    NavigationView {
      List {
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
          Section {
            NavigationLink("Optional-driven alerts") {
              OptionalAlerts()
            }
            NavigationLink("Optional confirmation dialogs") {
              OptionalConfirmationDialogs()
            }
          } header: {
            Text("Alerts and confirmation dialogs")
          }
        }

        Section {
          NavigationLink("Optional sheets") {
            OptionalSheets()
          }
          NavigationLink("Optional popovers") {
            OptionalPopovers()
          }
          NavigationLink("Optional full-screen covers") {
            OptionalFullScreenCovers()
          }
        } header: {
          Text("Sheets and full-screen covers")
        }

        Section {
          if #available(iOS 16, *) {
            NavigationLink("Optional destinations") {
              NavigationStack {
                NavigationDestinations()
              }
              .navigationTitle("Navigation stack")
            }
          }
          NavigationLink("Optional navigation links") {
            OptionalNavigationLinks()
          }
          NavigationLink("List of navigation links") {
            ListOfNavigationLinks(model: ListOfNavigationLinksModel())
          }
        } header: {
          Text("Navigation links")
        }

        Section {
          NavigationLink("Routing") {
            Routing()
          }
          NavigationLink("Custom components") {
            CustomComponents()
          }
          NavigationLink("Synchronized bindings") {
            SynchronizedBindings()
          }
        } header: {
          Text("Advanced")
        }
      }
      .navigationTitle("Case studies")
    }
    .navigationViewStyle(.stack)
  }
}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
