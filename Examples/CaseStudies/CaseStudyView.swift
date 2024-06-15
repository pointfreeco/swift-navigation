import SwiftUI

@MainActor
protocol CaseStudy: View {
  var readMe: String { get }
  var title: String { get }
  var usesOwnLayout: Bool { get }
}

@resultBuilder
enum CaseStudyViewBuilder {
  @MainActor
  static func buildExpression(_ caseStudy: some CaseStudy) -> some View {
    NavigationLink(caseStudy.title) {
      caseStudy
    }
  }
  static func buildPartialBlock(first: some View) -> some View {
    first
  }
  @ViewBuilder
  static func buildPartialBlock(accumulated: some View, next: some View) -> some View {
    accumulated
    next
  }
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

struct CaseStudyGroupView<Title: View, Content: View>: View {
  @CaseStudyViewBuilder let content: Content
  @ViewBuilder let title: Title

  var body: some View {
    Section {
      content
    } header: {
      title
    }
  }
}

extension CaseStudyGroupView where Title == Text {
  init(_ title: String, @CaseStudyViewBuilder content: () -> Content) {
    self.init(content: content) { Text(title) }
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
      CaseStudyGroupView("Group") {
        DemoCaseStudy()
      }
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
