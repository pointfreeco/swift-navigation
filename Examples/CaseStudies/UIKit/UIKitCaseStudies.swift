import SwiftUI
import SwiftUINavigation

struct UIKitCaseStudiesView: View {
  var body: some View {
    List {
      CaseStudyGroupView("Observation") {
        MinimalObservationViewController()
        AnimationsViewController()
      }
      CaseStudyGroupView("Bindings") {
        UIControlBindingsViewController()
        EnumControlsViewController()
        FocusViewController()
      }
      CaseStudyGroupView("Optional navigation") {
        BasicsNavigationViewController()
        // TODO: Alert/dialog state
        ConciseEnumNavigationViewController()
      }
      CaseStudyGroupView("Stack navigation") {
        StaticNavigationStackController(model: StaticNavigationStackController.Model())
        ErasedNavigationStackController(model: ErasedNavigationStackController.Model())
        // TODO: state restoration
      }
      CaseStudyGroupView("Advanced") {
        // TODO: Deep link
        // TODO: Dismissal (show off from VCs and views)
        WiFiSettingsViewController(model: WiFiSettingsModel(foundNetworks: .mocks))
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
