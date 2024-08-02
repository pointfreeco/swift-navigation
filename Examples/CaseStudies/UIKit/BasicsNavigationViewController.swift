import SwiftUI
import UIKit
import UIKitNavigation

class BasicsNavigationViewController: UIViewController, UIKitCaseStudy {
  let caseStudyTitle = "Basics"
  let readMe = """
    This case study demonstrates how to perform every major form of navigation in UIKit (alerts, \
    sheets, drill-downs) by driving navigation off of optional and boolean state.
    """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let showAlertButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.model.alert = "Hello!"
      })
    let showSheetButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.model.sheet = .random(in: 1...1_000)
      })
    let showSheetFromBooleanButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.model.isSheetPresented = true
      })
    let drillDownButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.model.drillDown = .random(in: 1...1_000)
      })

    let stack = UIStackView(arrangedSubviews: [
      showAlertButton,
      showSheetButton,
      drillDownButton,
      showSheetFromBooleanButton,
    ])
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])

    observe { [weak self] in
      guard let self else { return }

      showAlertButton.setTitle(
        "Alert is presented: \(model.alert != nil ? "✅" : "❌")",
        for: .normal
      )
      showSheetButton.setTitle(
        "Sheet is presented: \(model.sheet != nil ? "✅" : "❌")",
        for: .normal
      )
      showSheetFromBooleanButton.setTitle(
        "Sheet is presented from boolean: \(model.isSheetPresented ? "✅" : "❌")",
        for: .normal
      )
      drillDownButton.setTitle(
        "Drill-down is presented: \(model.drillDown != nil ? "✅" : "❌")",
        for: .normal
      )
    }

    present(item: $model.alert, id: \.self) { message in
      let alert = UIAlertController(
        title: "This is an alert",
        message: message,
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      return alert
    }
    present(item: $model.sheet, id: \.self) { count in
      let vc = UIHostingController(
        rootView: Form { Text(count.description) }
      )
      vc.mediumDetents()
      return vc
    }
    present(isPresented: $model.isSheetPresented) {
      let vc = UIHostingController(
        rootView: Form { Text("Hello!") }
      )
      vc.mediumDetents()
      return vc
    }
    navigationDestination(item: $model.drillDown) { count in
      UIHostingController(
        rootView: Form {
          Text(count.description)
        }
      )
    }
  }

  @Observable
  class Model {
    var alert: String?
    var drillDown: Int?
    var isSheetPresented = false
    var sheet: Int?
  }
}

#Preview {
  UINavigationController(
    rootViewController: BasicsNavigationViewController()
  )
}
