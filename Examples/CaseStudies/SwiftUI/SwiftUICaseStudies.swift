import SwiftUI
import SwiftUINavigation

struct SwiftUICaseStudiesView: View {
  var body: some View {
    List {
      CaseStudyGroupView("Optional-based navigation") {
        Alerts()
        AlertsWithAlertState()
        ConfirmationDialogs()
        Sheets()
        NavigationDestinations()
      }
      CaseStudyGroupView("Enum-based navigation") {
        MultipleDestinations()
      }
      CaseStudyGroupView("Miscellaneous") {
        SynchronizedBindings()
        CustomComponents()
      }
    }
    .navigationTitle("SwiftUI")
  }
}

#Preview {
  NavigationStack {
    SwiftUICaseStudiesView()
  }
}
