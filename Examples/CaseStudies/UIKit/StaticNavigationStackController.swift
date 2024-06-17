import SwiftUI
import UIKit
import UIKitNavigation

final class StaticNavigationStackController: NavigationStackController, UIKitCaseStudy {
  let caseStudyNavigationTitle = "Static path"
  let caseStudyTitle = "Statically typed path"
  let readMe = """
    TODO
    """
  let isPresentedInSheet = true
  private var model: Model!

  convenience init() {
    @UIBindable var model = Model()
    self.init(path: $model.path) {
      RootViewController()
    }
    self.navigationDestination(for: Model.Path.self) { path in
      switch path {
      case .feature1:
        Feature1ViewController()
      case .feature2:
        Feature1ViewController()
      case .feature3:
        Feature1ViewController()
      }
    }
    //self.model = model
  }

  deinit {
    print(Self.self, "deinit")
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
  override func viewDidLoad() {
    super.viewDidLoad()

    let feature1Button = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      self?.traitCollection.push(value: StaticNavigationStackController.Model.Path.feature1)
    })
    feature1Button.setTitle("Push feature 1", for: .normal)

    let stack = UIStackView(arrangedSubviews: [
      feature1Button,
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

private class Feature1ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    let feature1Button = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      self?.traitCollection.push(value: StaticNavigationStackController.Model.Path.feature1)
    })
    feature1Button.setTitle("Push feature 1 with traitCollection.push", for: .normal)

    let stack = UIStackView(arrangedSubviews: [
      feature1Button,
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
  StaticNavigationStackController()
}
