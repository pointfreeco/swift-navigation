import SwiftUI
import SwiftUINavigation

struct RootView: View {
  var body: some View {
    NavigationStack {
      List {
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
          NavigationLink("Optional destinations") {
            NavigationStack {
              NavigationDestinations()
            }
            .navigationTitle("Navigation stack")
          }
          NavigationLink("Optional navigation links") {
            OptionalNavigationLinks()
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
          NavigationLink("IfLet view") {
            IfLetCaseStudy()
          }
          NavigationLink("IfCaseLet view") {
            IfCaseLetCaseStudy()
          }
        } header: {
          Text("Advanced")
        }
      }
      .navigationTitle("Case studies")
    }
  }
}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
