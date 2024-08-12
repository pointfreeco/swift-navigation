import SwiftUI
import UIKit
import UIKitNavigation

final class ErasedNavigationStackController: NavigationStackController, UIKitCaseStudy {
  let caseStudyNavigationTitle = "Type-erased path"
  let caseStudyTitle = "Type-erased path"
  let readMe = """
    This case study demonstrates how to use the type erased `UINavigationPath` type to drive \
    navigation in a stack controller.
    """
  let isPresentedInSheet = true
  private var model: Model!

  convenience init(model: Model) {
    @UIBindable var model = model
    self.init(path: $model.path) {
      RootViewController(model: model)
    }
    self.model = model
  }

  @Observable
  class Model {
    var path = UINavigationPath()
  }
}

private class RootViewController: UIViewController {
  let model: ErasedNavigationStackController.Model
  init(model: ErasedNavigationStackController.Model) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    navigationDestination(for: Int.self) { number in
      NumberFeatureViewController(number: number)
    }

    let numberButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: Int.random(in: 1...1_000))
      })
    numberButton.setTitle("Push number feature", for: .normal)

    let deepLinkButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: Int.random(in: 1...1_000))
        self?.traitCollection.push(value: "Hello!")
        self?.traitCollection.push(value: Bool.random())
      })
    deepLinkButton.setTitle("Push features: number → string → bool", for: .normal)

    let stack = UIStackView(arrangedSubviews: [
      numberButton,
      deepLinkButton,
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

private class NumberFeatureViewController: UIViewController {
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

    navigationDestination(for: String.self) { string in
      StringFeatureViewController(string: string)
    }

    let numberButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: Int.random(in: 1...1_000))
      })
    numberButton.setTitle("Push number feature", for: .normal)

    let stringButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: "Hello!")
      })
    stringButton.setTitle("Push string feature", for: .normal)

    let dismissButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.dismiss()
      })
    dismissButton.setTitle("Dismiss", for: .normal)

    let stack = UIStackView(arrangedSubviews: [
      numberButton,
      stringButton,
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

private class StringFeatureViewController: UIViewController {
  let string: String
  init(string: String) {
    self.string = string
    super.init(nibName: nil, bundle: nil)
    title = "Feature '\(string)'"
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    navigationDestination(for: Bool.self) { bool in
      BoolFeatureViewController(bool: bool)
    }

    let numberButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: Int.random(in: 1...1_000))
      })
    numberButton.setTitle("Push number feature", for: .normal)

    let stringButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: "Hello!")
      })
    stringButton.setTitle("Push string feature", for: .normal)

    let boolButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: "\(Bool.random())")
      })
    boolButton.setTitle("Push boolean feature", for: .normal)

    let dismissButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.dismiss()
      })
    dismissButton.setTitle("Dismiss", for: .normal)

    let stack = UIStackView(arrangedSubviews: [
      numberButton,
      stringButton,
      boolButton,
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

private class BoolFeatureViewController: UIViewController {
  let bool: Bool
  init(bool: Bool) {
    self.bool = bool
    super.init(nibName: nil, bundle: nil)
    title = "Feature '\(bool)'"
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let numberButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: Int.random(in: 1...1_000))
      })
    numberButton.setTitle("Push number feature", for: .normal)

    let stringButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: "Hello!")
      })
    stringButton.setTitle("Push string feature", for: .normal)

    let boolButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.push(value: "\(Bool.random())")
      })
    boolButton.setTitle("Push boolean feature", for: .normal)

    let dismissButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.traitCollection.dismiss()
      })
    dismissButton.setTitle("Dismiss", for: .normal)

    let stack = UIStackView(arrangedSubviews: [
      numberButton,
      stringButton,
      boolButton,
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
  ErasedNavigationStackController(model: ErasedNavigationStackController.Model())
}
