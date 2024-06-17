import SwiftUI
import SwiftUINavigation

struct UIKitCaseStudiesView: View {
  var body: some View {
    List {
      CaseStudyGroupView("Observation") {
        MinimalObservationViewController() // ✅
        // TODO: Animation and transaction
      }
      CaseStudyGroupView("Bindings") {
        UIControlBindingsViewController()
        EnumControlsViewController()
      }
      CaseStudyGroupView("Optional navigation") {
        BasicsNavigationViewController() // ✅
        // TODO: Alert/dialog state
        ConciseEnumNavigationViewController() // ✅
      }
      CaseStudyGroupView("Stack navigation") {
        StaticPathStackNavigationController()
        ErasedPathStackNavigationController()
        // TODO: state restoration
      }
      CaseStudyGroupView("Advanced") {
        // TODO: Deep link
        // TODO: Dismissal (show off from VCs and views)
        WiFiSettingsViewController(
          model: WiFiSettingsModel(foundNetworks: .mocks)
        )
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
