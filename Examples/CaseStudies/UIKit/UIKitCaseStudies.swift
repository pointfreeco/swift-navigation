import SwiftUI
import SwiftUINavigation

struct UIKitCaseStudiesView: View {
  var body: some View {
    List {
      CaseStudyGroupView("Observation") {
        MinimalObservationViewController()
        // TODO: Animation and transaction
      }
      CaseStudyGroupView("Bindings") {
        BasicsBindingsViewController()
        EnumControlsViewController()
      }
      CaseStudyGroupView("Optional navigation") {
        SheetsViewController()
        MultipleDestinationsViewController()
      }
      CaseStudyGroupView("Stack navigation") {
        StaticPathStackNavigationController()
        ErasedPathStackNavigationController()
        // TODO: state restoration
      }
      CaseStudyGroupView("Advanced") {
        // TODO: Deep link
        // TODO: Dismissal (show off from VCs and views)
      }
    }
    .navigationTitle("UIKit")
  }
}

#Preview {
  NavigationStack {
    UIKitCaseStudiesView()
  }
}
