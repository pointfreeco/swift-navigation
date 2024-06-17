import SwiftUI

struct SwiftUICaseStudiesView: View {
  var body: some View {
    List {
      CaseStudyGroupView("Navigation") {
        OptionalNavigation()
        EnumNavigation()
        AlertsWithAlertState()
      }
      CaseStudyGroupView("Binding helpers") {
        SynchronizedBindings()
        EnumControls()
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
