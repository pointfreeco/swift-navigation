import SwiftUI
import UIKit
import UIKitNavigation

class AlertsViewController: UIViewController, UIKitCaseStudy {
  let caseStudyTitle = "Alerts"
  let readMe = """
    This case study demonstrates how to present an alert using the 'present(item:)' method.
    """
  var body: some View { EmptyView() }
  @UIBindable var model = Alerts.Model()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let countLabel = UILabel()
    countLabel.textAlignment = .center
    let decrementButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      self?.model.count -= 1
    })
    decrementButton.setTitle("Decrement", for: .normal)
    let incrementButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      self?.model.count += 1
    })
    incrementButton.setTitle("Increment", for: .normal)
    let activityIndicator = UIActivityIndicatorView()
    activityIndicator.startAnimating()
    let factButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      guard let self else { return }
      Task { await self.model.numberFactButtonTapped() }
    })
    factButton.setTitle("Get fact", for: .normal)

    let counterStack = UIStackView(arrangedSubviews: [
      countLabel,
      decrementButton,
      incrementButton,
      activityIndicator,
      factButton,
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

    observe { [weak self] in
      guard let self else { return }

      countLabel.text = "\(model.count)"
      activityIndicator.isHidden = !model.isLoading
      factButton.isEnabled = !model.isLoading
    }

    present(item: $model.fact) { fact in
      let alert = UIAlertController.init(
        title: "Fact about \(fact.number)",
        message: fact.description,
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      return alert
    }
  }
}

#Preview {
  UINavigationController(rootViewController: AlertsViewController())
}
