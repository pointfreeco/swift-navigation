import SwiftUI

protocol CaseStudy: View {
  var readMe: String { get }
  var title: String { get }
  var usesOwnLayout: Bool { get }
}

extension CaseStudy {
  var usesOwnLayout: Bool { false }
}

struct CaseStudyView<C: CaseStudy>: View {
  @ViewBuilder let caseStudy: C

  var body: some View {
    Group {
      if caseStudy.usesOwnLayout {
        caseStudy
      } else {
        Form {
          Section {
            DisclosureGroup("About this case study") {
              Text(caseStudy.readMe)
            }
          }
          caseStudy
        }
      }
    }
    .navigationTitle(caseStudy.title)
  }
}

struct CaseStudyGroupView<Title: View, each C: CaseStudy>: View {
  let title: Title
  let caseStudies: (repeat each C)

  var body: some View {
    Section {
      TupleView((repeat (each caseStudies).navigationLink()))
    } header: {
      title
    }
  }
}

extension CaseStudy {
  fileprivate func navigationLink() -> some View {
    NavigationLink(title) {
      self
    }
  }
}

#Preview("Case study") {
  NavigationStack {
    CaseStudyView {
      DemoCaseStudy()
    }
  }
}

#Preview("Case study group") {
  NavigationStack {
    Form {
      CaseStudyGroupView(
        title: Text("Group"),
        caseStudies: (
          DemoCaseStudy()
        )
      )
    }
  }
}

private struct DemoCaseStudy: CaseStudy {
  let title = "Demo Case Study"
  let readMe = """
    Hello! This is a demo case study.

    Enjoy!
    """
  var body: some View {
    Text("Hello!")
  }
}
