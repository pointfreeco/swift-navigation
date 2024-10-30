import SwiftUI
import UIKitNavigation

@MainActor
protocol CaseStudy {
  var readMe: String { get }
  var caseStudyTitle: String { get }
  var caseStudyNavigationTitle: String { get }
  var usesOwnLayout: Bool { get }
  var isPresentedInSheet: Bool { get }
}
protocol SwiftUICaseStudy: CaseStudy, View {}
protocol UIKitCaseStudy: CaseStudy, UIViewController {}

extension CaseStudy {
  var caseStudyNavigationTitle: String { caseStudyTitle }
  var isPresentedInSheet: Bool { false }
}
extension SwiftUICaseStudy {
  var usesOwnLayout: Bool { false }
}
extension UIKitCaseStudy {
  var usesOwnLayout: Bool { true }
}

@resultBuilder
@MainActor
enum CaseStudyViewBuilder {
  @ViewBuilder
  static func buildBlock() -> some View {}
  @ViewBuilder
  static func buildExpression(_ caseStudy: some SwiftUICaseStudy) -> some View {
    SwiftUICaseStudyButton(caseStudy: caseStudy)
  }
  @ViewBuilder
  static func buildExpression(_ caseStudy: some UIKitCaseStudy) -> some View {
    UIKitCaseStudyButton(caseStudy: caseStudy)
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

struct SwiftUICaseStudyButton<C: SwiftUICaseStudy>: View {
  let caseStudy: C
  @State var isPresented = false
  var body: some View {
    if caseStudy.isPresentedInSheet {
      Button(caseStudy.caseStudyTitle) {
        isPresented = true
      }
      .sheet(isPresented: $isPresented) {
        CaseStudyView {
          caseStudy
        }
        .modifier(CaseStudyModifier(caseStudy: caseStudy))
      }
    } else {
      NavigationLink(caseStudy.caseStudyTitle) {
        CaseStudyView {
          caseStudy
        }
        .modifier(CaseStudyModifier(caseStudy: caseStudy))
      }
    }
  }
}

struct UIKitCaseStudyButton<C: UIKitCaseStudy>: View {
  let caseStudy: C
  @State var isPresented = false
  var body: some View {
    if caseStudy.isPresentedInSheet {
      Button(caseStudy.caseStudyTitle) {
        isPresented = true
      }
      .sheet(isPresented: $isPresented) {
        UIViewControllerRepresenting {
          ((caseStudy as? UINavigationController)
            ?? UINavigationController(rootViewController: caseStudy))
            .setUp(caseStudy: caseStudy)
        }
        .modifier(CaseStudyModifier(caseStudy: caseStudy))
      }
    } else {
      NavigationLink(caseStudy.caseStudyTitle) {
        UIViewControllerRepresenting {
          caseStudy
        }
        .modifier(CaseStudyModifier(caseStudy: caseStudy))
      }
    }
  }
}

extension UINavigationController {
  func setUp(caseStudy: some CaseStudy) -> Self {
    self.viewControllers[0].title = caseStudy.caseStudyNavigationTitle
    self.viewControllers[0].navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "About",
      primaryAction: UIAction { [weak self] _ in
        self?.present(
          UIHostingController(
            rootView: Form {
              Text(template: caseStudy.readMe)
            }
            .presentationDetents([.medium])
          ),
          animated: true
        )
      })
    return self
  }
}

struct CaseStudyModifier<C: CaseStudy>: ViewModifier {
  let caseStudy: C
  @State var isAboutPresented = false
  func body(content: Content) -> some View {
    content
      .navigationTitle(caseStudy.caseStudyNavigationTitle)
      .toolbar {
        ToolbarItem {
          Button("About") { isAboutPresented = true }
        }
      }
      .sheet(isPresented: $isAboutPresented) {
        Form {
          Text(template: caseStudy.readMe)
        }
        .presentationDetents([.medium])
      }
  }
}

struct CaseStudyView<C: SwiftUICaseStudy>: View {
  @ViewBuilder let caseStudy: C
  @State var isAboutPresented = false
  var body: some View {
    if caseStudy.usesOwnLayout {
      VStack {
        caseStudy
      }
    } else {
      Form {
        caseStudy
      }
    }
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

extension SwiftUICaseStudy {
  fileprivate func navigationLink() -> some View {
    NavigationLink(caseStudyTitle) {
      self
    }
  }
}

#Preview("SwiftUI case study") {
  NavigationStack {
    CaseStudyView {
      DemoCaseStudy()
    }
  }
}

#Preview("SwiftUI case study group") {
  NavigationStack {
    Form {
      CaseStudyGroupView("Group") {
        DemoCaseStudy()
      }
    }
  }
}

private struct DemoCaseStudy: SwiftUICaseStudy {
  let caseStudyTitle = "Demo Case Study"
  let readMe = """
    Hello! This is a demo case study.

    Enjoy!
    """
  var body: some View {
    Text("Hello!")
  }
}

private class DemoCaseStudyController: UIViewController, UIKitCaseStudy {
  let caseStudyTitle = "Demo Case Study"
  let readMe = """
    Hello! This is a demo case study.

    Enjoy!
    """
}
