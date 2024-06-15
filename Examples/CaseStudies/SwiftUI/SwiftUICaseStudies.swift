import SwiftUI
import SwiftUINavigation

struct SwiftUICaseStudiesView: View {
  let caseStudies = [
    SynchronizedBindings()
  ]

  var body: some View {
    List {
      CaseStudyGroupView(
        title: Text("Miscellaneous"),
        caseStudies: (
          SynchronizedBindings(),
          CustomComponents()
        )
      )
    }
  }
}

#Preview {
  NavigationStack {
    SwiftUICaseStudiesView()
  }
}
