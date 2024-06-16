import SwiftUI
import SwiftUINavigation

struct UIKitCaseStudiesView: View {
  var body: some View {
    List {
      CaseStudyGroupView("Optional-based navigation") {
        AlertsViewController()
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
