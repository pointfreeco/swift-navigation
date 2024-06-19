import SwiftUI
import UIKit
import UIKitNavigation

class FocusViewController: UIViewController, UIKitCaseStudy {
  let caseStudyTitle = "Basics"
  let readMe = """
    This case study demonstrates how to perform every major form of navigation in UIKit (alerts, \
    sheets, drill-downs) by driving navigation off of optional and boolean state.
    """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()

    let bioTextField = UITextField(text: $model.bio)
    bioTextField.bind(focus: $model.focus, equals: .bio)
    bioTextField.borderStyle = .roundedRect
    bioTextField.placeholder = "Bio"
    let emailTextField = UITextField(text: $model.email)
    emailTextField.bind(focus: $model.focus, equals: .email)
    emailTextField.borderStyle = .roundedRect
    emailTextField.placeholder = "Email"
    let passwordTextField = UITextField(text: $model.password)
    passwordTextField.bind(focus: $model.focus, equals: .password)
    passwordTextField.borderStyle = .roundedRect
    passwordTextField.isSecureTextEntry = true
    passwordTextField.placeholder = "Password"
    let usernameTextField = UITextField(text: $model.username)
    usernameTextField.bind(focus: $model.focus, equals: .username)
    usernameTextField.borderStyle = .roundedRect
    usernameTextField.placeholder = "Username"

    let currentFocusLabel = UILabel()

    let focusBioButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      self?.model.focus = .bio
    })
    focusBioButton.setTitle("Focus bio", for: .normal)
    let focusEmailButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      self?.model.focus = .email
    })
    focusEmailButton.setTitle("Focus email", for: .normal)
    let focusPasswordButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      self?.model.focus = .password
    })
    focusPasswordButton.setTitle("Focus password", for: .normal)
    let focusUsernameButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      self?.model.focus = .username
    })
    focusUsernameButton.setTitle("Focus username", for: .normal)

    let stack = UIStackView(arrangedSubviews: [
      usernameTextField,
      emailTextField,
      passwordTextField,
      bioTextField,
      currentFocusLabel,
      focusUsernameButton,
      focusEmailButton,
      focusPasswordButton,
      focusBioButton,
    ])
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      stack.leadingAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
      stack.trailingAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
    ])

    observe { [weak self] in
      guard let self else { return }

      currentFocusLabel.text = "Current focus: \(model.focus?.rawValue ?? "none")"
      bioTextField.backgroundColor = .systemBackground
      emailTextField.backgroundColor = .systemBackground
      passwordTextField.backgroundColor = .systemBackground
      usernameTextField.backgroundColor = .systemBackground
      switch model.focus {
      case .bio:
        bioTextField.backgroundColor = .lightGray
      case .email:
        emailTextField.backgroundColor = .lightGray
      case .password:
        passwordTextField.backgroundColor = .lightGray
      case .username:
        usernameTextField.backgroundColor = .lightGray
      case .none:
        break
      }
    }
  }

  @Observable
  class Model {
    var bio = ""
    var email = ""
    var focus: Focus?
    var password = ""
    var username = ""
    enum Focus: String { case bio, email, password, username }
  }
}

#Preview {
  FocusViewController()
}
