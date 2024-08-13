import SwiftUI
import UIKit
import UIKitNavigation

final class StaticNavigationStackController: NavigationStackController, UIKitCaseStudy {
  let caseStudyNavigationTitle = "Static path"
  let caseStudyTitle = "Statically typed path"
  let readMe = """
    This case study demonstrates how to use the `NavigationStackController` class, which is a \
    UIKit replacement for SwiftUI's `NavigationStack`.

    Each screen can push a new element onto the stack by using the `push(value:)` trait, and \
    each feature can dismiss itself using the `dismiss()` trait.
    """
  let isPresentedInSheet = true
  private var model: Model!

  convenience init(model: Model) {
    @UIBindable var model = model
    self.init(path: $model.path) {
      RootViewController(model: model)
    }
    self.navigationDestination(for: Model.Path.self) { path in
      switch path {
      case .feature1:
        FeatureViewController(number: 1)
      case .feature2:
        FeatureViewController(number: 2)
      case .feature3:
        FeatureViewController(number: 3)
      }
    }
    self.model = model
  }

  @Observable
  class Model {
    var path: [Path] = []
    @CasePathable
    enum Path {
      case feature1
      case feature2
      case feature3
    }
  }
}

private class RootViewController: UIViewController {
  let model: StaticNavigationStackController.Model
  init(model: StaticNavigationStackController.Model) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let feature1Button = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: StaticNavigationStackController.Model.Path.feature1)
      })
    feature1Button.setTitle("Push feature 1", for: .normal)

    let feature2Button = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: StaticNavigationStackController.Model.Path.feature2)
      })
    feature2Button.setTitle("Push feature 2", for: .normal)

    let feature3Button = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: StaticNavigationStackController.Model.Path.feature3)
      })
    feature3Button.setTitle("Push feature 3", for: .normal)

    let feature123Button = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.model.path.append(contentsOf: [
          .feature1,
          .feature2,
          .feature3,
        ])
      })
    feature123Button.setTitle("Push feature 1 → 2 → 3", for: .normal)

    let stack = UIStackView(arrangedSubviews: [
      feature1Button,
      feature2Button,
      feature3Button,
      feature123Button,
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
  }
}

private class FeatureViewController: UIViewController {
  let number: Int
  init(number: Int) {
    self.number = number
    super.init(nibName: nil, bundle: nil)
    title = "Feature \(number)"
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let feature1Button = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: StaticNavigationStackController.Model.Path.feature1)
      })
    feature1Button.setTitle("Push feature 1", for: .normal)

    let feature2Button = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: StaticNavigationStackController.Model.Path.feature2)
      })
    feature2Button.setTitle("Push feature 2", for: .normal)

    let feature3Button = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: StaticNavigationStackController.Model.Path.feature3)
      })
    feature3Button.setTitle("Push feature 3", for: .normal)

    let dismissButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.dismiss()
      })
    dismissButton.setTitle("Dismiss", for: .normal)

    let stack = UIStackView(arrangedSubviews: [
      feature1Button,
      feature2Button,
      feature3Button,
      dismissButton,
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
  }
}

#Preview {
  StaticNavigationStackController(model: StaticNavigationStackController.Model())
}
