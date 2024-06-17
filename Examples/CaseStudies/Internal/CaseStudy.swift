import SwiftUI
import UIKitNavigation

protocol CaseStudy {
  var readMe: String { get }
  var caseStudyTitle: String { get }
  var usesOwnLayout: Bool { get }
}
protocol SwiftUICaseStudy: CaseStudy, View {}
protocol UIKitCaseStudy: CaseStudy, UIViewController {}

extension CaseStudy {
  var usesOwnLayout: Bool { false }
}

@resultBuilder
@MainActor
enum CaseStudyViewBuilder {
  @ViewBuilder
  static func buildBlock() -> some View {}
  static func buildExpression(_ caseStudy: some SwiftUICaseStudy) -> some View {
    NavigationLink(caseStudy.caseStudyTitle) {
      CaseStudyView { caseStudy }
    }
  }
  static func buildExpression(_ caseStudy: some UIKitCaseStudy) -> some View {
    NavigationLink(caseStudy.caseStudyTitle) {
      UIViewControllerRepresenting {
        caseStudy
      }
      .modifier(UIKitCaseStudyModifier(caseStudy: caseStudy))
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

struct UIKitCaseStudyModifier<C: CaseStudy>: ViewModifier {
  @State var isAboutPresented = false
  let caseStudy: C
  func body(content: Content) -> some View {
    content
      .navigationTitle(caseStudy.caseStudyTitle)
      .toolbar {
        ToolbarItem {
          Button("About") { isAboutPresented = true }
        }
      }
      .sheet(isPresented: $isAboutPresented) {
        Form {
          Text(caseStudy.readMe)
        }
        .presentationDetents([.medium])
      }
  }
}

struct CaseStudyView<C: SwiftUICaseStudy>: View {
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
    .navigationTitle(caseStudy.caseStudyTitle)
  }
}

class CaseStudyViewController<C: UIKitCaseStudy>: UIViewController {
  let controller: C
  init(controller: C) {
    self.controller = controller
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    title = controller.caseStudyTitle
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "About",
      primaryAction: UIAction { [weak self] _ in
        guard let self else { return }
        present(AboutViewController(readMe: controller.readMe), animated: true)
    })
    addChild(controller)
    view.addSubview(controller.view)
    controller.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      controller.view.topAnchor.constraint(equalTo: view.topAnchor),
    ])
  }

  private class AboutViewController: UIViewController {
    let readMe: String
    init(readMe: String) {
      self.readMe = readMe
      super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
      super.viewDidLoad()
      view.backgroundColor = .systemBackground
      let readMeLabel = UILabel()
      readMeLabel.text = readMe
      view.addSubview(readMeLabel)
      readMeLabel.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        readMeLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
        readMeLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        readMeLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 12),
      ])
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

#Preview("UIKit case study") {
  UIViewControllerRepresenting {
    UINavigationController(
      rootViewController: CaseStudyViewController(
        controller: DemoCaseStudyController()
      )
    )
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
