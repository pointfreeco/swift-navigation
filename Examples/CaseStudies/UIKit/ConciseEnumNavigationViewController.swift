import SwiftUI
import UIKit
import UIKitNavigation

class ConciseEnumNavigationViewController: UIViewController, UIKitCaseStudy {
  let caseStudyNavigationTitle = "Enum navigation"
  let caseStudyTitle = "Concise enum navigation"
  let readMe = """
    This case study demonstrates how to navigate to multiple destinations from a single optional \
    enum.

    This allows you to be very concise with your domain modeling by having a single enum \
    describe all the possible destinations you can navigate to. In the case of this demo, we have \
    four cases in the enum, which means there are exactly 5 possible states, including the case \
    where none are active.

    If you were to instead model this domain with 4 optionals (or booleans), then you would have \
    16 possible states, of which only 5 are valid. That can leak complexity into your domain \
    because you can never be sure of exactly what is presented at a given time.
    """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let showAlertButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.model.destination = .alert("Hello!")
      })
    let showSheetButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.model.destination = .sheet(.random(in: 1...1_000))
      })
    let showSheetFromBooleanButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.model.destination = .sheetWithoutPayload
      })
    let drillDownButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.model.destination = .drillDown(.random(in: 1...1_000))
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
        "Alert is presented: \(model.destination?.alert != nil ? "✅" : "❌")",
        for: .normal
      )
      showSheetButton.setTitle(
        "Sheet is presented: \(model.destination?.sheet != nil ? "✅" : "❌")",
        for: .normal
      )
      showSheetFromBooleanButton.setTitle(
        "Sheet is presented from boolean: \(model.destination?.sheetWithoutPayload != nil ? "✅" : "❌")",
        for: .normal
      )
      drillDownButton.setTitle(
        "Drill-down is presented: \(model.destination?.drillDown != nil ? "✅" : "❌")",
        for: .normal
      )
    }

    present(item: $model.destination.alert, id: \.self) { message in
      let alert = UIAlertController(
        title: "This is an alert",
        message: message,
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      return alert
    }
    present(item: $model.destination.sheet, id: \.self) { count in
      let vc = UIHostingController(
        rootView: Form { Text(count.description) }
      )
      vc.mediumDetents()
      return vc
    }
    present(isPresented: UIBinding($model.destination.sheetWithoutPayload)) {
      let vc = UIHostingController(
        rootView: Form { Text("Hello!") }
      )
      vc.mediumDetents()
      return vc
    }
    navigationDestination(item: $model.destination.drillDown) { count in
      UIHostingController(
        rootView: Form {
          Text(count.description)
        }
      )
    }
  }

  @Observable
  class Model {
    var destination: Destination?
    @CasePathable
    @dynamicMemberLookup
    enum Destination {
      case alert(String)
      case drillDown(Int)
      case sheet(Int)
      case sheetWithoutPayload
    }
  }
}

#Preview {
  UINavigationController(
    rootViewController: BasicsNavigationViewController()
  )
}
