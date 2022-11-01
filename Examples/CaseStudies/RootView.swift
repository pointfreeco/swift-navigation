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
          if #available(iOS 14, *) {
            NavigationLink("Optional full-screen covers") {
              OptionalFullScreenCovers()
            }
          }
        } header: {
          Text("Sheets and full-screen covers")
        }

        Section {
          if #available(iOS 16, *) {
            NavigationLink("Navigation destinations") {
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
            ListOfNavigationLinks(viewModel: .init())
          }
        } header: {
          Text("Navigation")
        }

        Section {
          if #available(iOS 15, *) {
            NavigationLink("Routing") {
              Routing()
            }
          }
          NavigationLink("Custom components") {
            CustomComponents()
          }
        } header: {
          Text("Advanced")
        }
      }
      .navigationBarTitle("Case studies")
    }
    .navigationViewStyle(.stack)
  }
}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
