#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import SwiftUI
import SwiftUINavigation

struct AppKitCaseStudiesView: View {
    var body: some View {
        List {
            CaseStudyGroupView("Observation") {
                MinimalObservationViewController()
//        AnimationsViewController()
            }
            CaseStudyGroupView("Bindings") {
                NSControlBindingsViewController()
                EnumControlsViewController()
                FocusViewController()
            }
            CaseStudyGroupView("Optional navigation") {
                BasicsNavigationViewController()
                // TODO: Alert/dialog state
                ConciseEnumNavigationViewController()
            }
//      CaseStudyGroupView("Stack navigation") {
//        StaticNavigationStackController()
//        ErasedNavigationStackController(model: ErasedNavigationStackController.Model())
//        // TODO: state restoration
//      }
            CaseStudyGroupView("Advanced") {
                // TODO: Deep link
                // TODO: Dismissal (show off from VCs and views)
                WiFiSettingsViewController(model: WiFiSettingsModel(foundNetworks: .mocks))
            }
        }
        .navigationTitle("AppKit")
    }
}

#Preview {
    NavigationStack {
        AppKitCaseStudiesView()
    }
}
#endif
