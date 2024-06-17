import SwiftUI
import UIKit
import UIKitNavigation

class MultipleDestinationsViewController: UIViewController, UIKitCaseStudy {
  let caseStudyTitle = "Concise enum navigation"
  let readMe = """
    This case study demonstrates how to navigate to multiple destinations from a single optional \
    enum.
    """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let alertButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      self?.model.destination = .alert("Hello!")
    })
    alertButton.setTitle("Show alert", for: .normal)

    let pushButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      self?.model.destination = .push("Hello!")
    })
    pushButton.setTitle("Push screen", for: .normal)

    let sheetButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      self?.model.destination = .sheet("Hello!")
    })
    sheetButton.setTitle("Show sheet", for: .normal)

    let counterStack = UIStackView(arrangedSubviews: [
      alertButton,
      pushButton,
      sheetButton,
    ])
    counterStack.axis = .vertical
    counterStack.spacing = 12
    counterStack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(counterStack)
    NSLayoutConstraint.activate([
      counterStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      counterStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      counterStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      counterStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])

    present(item: $model.destination.alert, id: \.self) { message in
      let alert = UIAlertController.init(
        title: "This is an alert!",
        message: message,
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      return alert
    }

    pushViewController(item: $model.destination.push) { message in
      UIHostingController(
        rootView: Text(message)
          .padding()
      )
    }

    present(item: $model.destination.sheet, id: \.self) { message in
      UIHostingController(
        rootView: Text(message)
          .padding()
      )
    }
  }

  @Observable 
  class Model {
    var destination: Destination?
    @CasePathable
    enum Destination {
      case alert(String)
      case push(String)
      case sheet(String)
    }
  }
}

#Preview {
  UINavigationController(rootViewController: MultipleDestinationsViewController())
}
