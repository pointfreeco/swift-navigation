#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import AppKitNavigation

class FocusViewController: XiblessViewController<NSView>, AppKitCaseStudy {
    let caseStudyTitle = "Focus"
    let readMe = """
    This case study demonstrates how to handle `UITextField` focus in a state-driven manner. The \
    focus in the UI is kept in sync with the focus value held in an observable model so that \
    changes in one are immediately reflected in the other.
    """
    @UIBindable var model = Model()

    override func viewDidLoad() {
        super.viewDidLoad()

        let bioTextField = NSTextField(text: $model.bio)
        bioTextField.bind(focus: $model.focus, equals: .bio)
        bioTextField.bezelStyle = .roundedBezel
        bioTextField.placeholderString = "Bio"
        let emailTextField = NSTextField(text: $model.email)
        emailTextField.bind(focus: $model.focus, equals: .email)
        emailTextField.bezelStyle = .roundedBezel
        emailTextField.placeholderString = "Email"
        let passwordTextField = NSSecureTextField(text: $model.password)
        passwordTextField.bind(focus: $model.focus, equals: .password)
        passwordTextField.bezelStyle = .roundedBezel
        passwordTextField.placeholderString = "Password"
        let usernameTextField = NSTextField(text: $model.username)
        usernameTextField.bind(focus: $model.focus, equals: .username)
        usernameTextField.bezelStyle = .roundedBezel
        usernameTextField.placeholderString = "Username"

        let currentFocusLabel = NSTextField(labelWithString: "")

        let focusBioButton = NSButton { [weak self] _ in
            self?.model.focus = .bio
        }

        focusBioButton.title = "Focus bio"
        let focusEmailButton = NSButton { [weak self] _ in
            self?.model.focus = .email
        }

        focusEmailButton.title = "Focus email"
        let focusPasswordButton = NSButton { [weak self] _ in
            self?.model.focus = .password
        }

        focusPasswordButton.title = "Focus password"
        let focusUsernameButton = NSButton { [weak self] _ in
            self?.model.focus = .username
        }

        focusUsernameButton.title = "Focus username"
        let resignFirstResponder = NSButton { [weak self] _ in
            self?.view.window?.makeFirstResponder(nil)
        }

        resignFirstResponder.title = "Resign first responder"

        let stack = NSStackView(views: [
            usernameTextField,
            emailTextField,
            passwordTextField,
            bioTextField,
            currentFocusLabel,
            focusUsernameButton,
            focusEmailButton,
            focusPasswordButton,
            focusBioButton,
            resignFirstResponder,
        ])
        stack.orientation = .vertical
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

            currentFocusLabel.stringValue = "Current focus: \(model.focus?.rawValue ?? "none")"
            bioTextField.backgroundColor = nil
            emailTextField.backgroundColor = nil
            passwordTextField.backgroundColor = nil
            usernameTextField.backgroundColor = nil
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
        enum Focus: String { 
            case bio
            case email
            case password
            case username
        }
    }
}

#Preview {
    FocusViewController()
}

#endif
