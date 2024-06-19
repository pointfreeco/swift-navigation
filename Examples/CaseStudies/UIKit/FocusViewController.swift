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
    let emailTextField = UITextField(text: $model.email)
    emailTextField.bind(focus: $model.focus, equals: .email)
    emailTextField.borderStyle = .roundedRect
    let passwordTextField = UITextField(text: $model.password)
    passwordTextField.bind(focus: $model.focus, equals: .password)
    passwordTextField.borderStyle = .roundedRect
    let usernameTextField = UITextField(text: $model.username)
    usernameTextField.bind(focus: $model.focus, equals: .username)
    usernameTextField.borderStyle = .roundedRect

    let stack = UIStackView(arrangedSubviews: [
      usernameTextField,
      emailTextField,
      passwordTextField,
      bioTextField,
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

  @Observable
  class Model {
    var bio = ""
    var email = ""
    var focus: Focus?
    var password = ""
    var username = ""
    enum Focus { case bio, email, password, username }
  }
}

#Preview {
  FocusViewController()
}
