import SwiftUI
import SwiftUINavigation

struct SwiftUICaseStudiesView: View {
  let caseStudies = [
    SynchronizedBindings()
  ]

  var body: some View {
    List {
      CaseStudyGroupView("Miscellaneous") {
        SynchronizedBindings()
        CustomComponents()
      }
    }
  }
}

#Preview {
  NavigationStack {
    SwiftUICaseStudiesView()
  }
}
