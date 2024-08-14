#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import SwiftNavigation

extension NSTextField: NSTextViewDelegate {
    /// Creates a new text field with the specified frame and registers the binding against its
    /// text.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - text: The binding to read from for the current text, and write to when the text
    ///     changes.
    public convenience init(frame: CGRect = .zero, text: UIBinding<String>) {
        self.init(frame: frame)
        bind(text: text)
    }

    /// Creates a new text field with the specified frame and registers the binding against its
    /// text.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - attributedText: The binding to read from for the current text, and write to when the
    ///     attributed text changes.
    public convenience init(frame: CGRect = .zero, attributedText: UIBinding<NSAttributedString>) {
        self.init(frame: frame)
        bind(attributedText: attributedText)
    }

    /// Establishes a two-way connection between a binding and the text field's current text.
    ///
    /// - Parameter text: The binding to read from for the current text, and write to when the text
    ///   changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(text: UIBinding<String>) -> ObservationToken {
        bind(text, to: \.stringValue)
    }

    /// Establishes a two-way connection between a binding and the text field's current text.
    ///
    /// - Parameter attributedText: The binding to read from for the current text, and write to when
    ///   the attributed text changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(attributedText: UIBinding<NSAttributedString>) -> ObservationToken {
        bind(attributedText, to: \.attributedStringValue)
    }

    /// Establishes a two-way connection between a binding and the text field's current selection.
    ///
    /// - Parameter selection: The binding to read from for the current selection, and write to when
    ///   the selected text range changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(selection: UIBinding<AppKitTextSelection?>) -> ObservationToken {
        let editingChangedAction = NotificationCenter.default.publisher(for: NSTextField.textDidChangeNotification, object: self)
            .sink { [weak self] _ in
                guard let self else { return }
                selection.wrappedValue = self.textSelection
            }
        let editingDidEndAction = NotificationCenter.default.publisher(for: NSTextField.textDidEndEditingNotification, object: self).sink { _ in selection.wrappedValue = nil }
        let token = observe { [weak self] in
            guard let self else { return }
            textSelection = selection.wrappedValue
        }
        textSelectionObserver = TextSelectionObserver { control in
            MainActor._assumeIsolated {
                selection.wrappedValue = control.textSelection
            }
        }
        
        let observationToken = ObservationToken { [weak self] in
//            MainActor._assumeIsolated {
            editingChangedAction.cancel()
            editingDidEndAction.cancel()
//            }
            token.cancel()
            self?.textSelectionObserver = nil
        }
        observationTokens[\NSTextField.selectedRange] = observationToken
        return observationToken
    }

    fileprivate var selectedRange: NSRange? {
        set {
            currentEditor()?.selectedRange = newValue ?? .init(location: 0, length: 0)
        }

        get {
            currentEditor()?.selectedRange
        }
    }

    fileprivate class TextSelectionObserver: NSObject {
        let observer: (NSTextField) -> Void

        init(observer: @escaping (NSTextField) -> Void) {
            self.observer = observer
        }
    }

    private static let textSelectionObserverKey = malloc(1)!
    private var textSelectionObserver: TextSelectionObserver? {
        set {
            objc_setAssociatedObject(self, Self.textSelectionObserverKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            objc_getAssociatedObject(self, Self.textSelectionObserverKey) as? TextSelectionObserver
        }
    }

    public func textViewDidChangeSelection(_ notification: Notification) {
        textSelectionObserver?.observer(self)
    }

    fileprivate var textSelection: AppKitTextSelection? {
        get {
            guard
                let textRange = selectedRange
            else {
                return nil
            }
            let text = stringValue
            let lowerBound =
                text.index(
                    text.startIndex,
                    offsetBy: textRange.location,
                    limitedBy: text.endIndex
                ) ?? text.endIndex
            let upperBound =
                text.index(
                    text.startIndex,
                    offsetBy: NSMaxRange(textRange),
                    limitedBy: text.endIndex
                ) ?? text.endIndex
            return AppKitTextSelection(range: lowerBound ..< upperBound)
        }
        set {
            guard let selection = newValue?.range else {
                selectedRange = nil
                return
            }
            let text = stringValue
            let from = text.distance(
                from: text.startIndex, to: min(selection.lowerBound, text.endIndex)
            )
            let to = text.distance(
                from: text.startIndex, to: min(selection.upperBound, text.endIndex)
            )
            selectedRange = .init(location: from, length: to - from)
        }
    }

    /// Modifies this text field by binding its focus state to the given state value.
    ///
    /// Use this modifier to cause the text field to receive focus whenever the the `binding` equals
    /// the `value`. Typically, you create an enumeration of fields that may receive focus, bind an
    /// instance of this enumeration, and assign its cases to focusable text fields.
    ///
    /// The following example uses the cases of a `LoginForm` enumeration to bind the focus state of
    /// two `UITextField` views. A sign-in button validates the fields and sets the bound
    /// `focusedField` value to any field that requires the user to correct a problem.
    ///
    /// ```swift
    /// final class LoginViewController: UIViewController {
    ///   enum Field {
    ///     case usernameField
    ///     case passwordField
    ///   }
    ///
    ///   @UIBinding private var username = ""
    ///   @UIBinding private var password = ""
    ///   @UIBinding private var focusedField: Field?
    ///
    ///   // ...
    ///
    ///   override func viewDidLoad() {
    ///     super.viewDidLoad()
    ///
    ///     let usernameTextField = UITextField(text: $username)
    ///     usernameTextField.focus($focusedField, equals: .usernameField)
    ///
    ///     let passwordTextField = UITextField(text: $password)
    ///     passwordTextField.focus($focusedField, equals: .passwordField)
    ///     passwordTextField.isSecureTextEntry = true
    ///
    ///     let signInButton = UIButton(
    ///       style: .system,
    ///       primaryAction: UIAction { [weak self] _ in
    ///         guard let self else { return }
    ///         if username.isEmpty {
    ///           focusedField = .usernameField
    ///         } else if password.isEmpty {
    ///           focusedField = .passwordField
    ///         } else {
    ///           handleLogin(username, password)
    ///         }
    ///       }
    ///     )
    ///     signInButton.setTitle("Sign In", for: .normal)
    ///
    ///     // ...
    ///   }
    /// }
    /// ```
    ///
    /// To control focus using a Boolean, use the ``UIKit/UITextField/bind(focus:)`` method instead.
    ///
    /// - Parameters:
    ///   - focus: The state binding to register. When focus moves to the text field, the binding
    ///     sets the bound value to the corresponding match value. If a caller sets the state value
    ///     programmatically to the matching value, then focus moves to the text field. When focus
    ///     leaves the text field, the binding sets the bound value to `nil`. If a caller sets the
    ///     value to `nil`, UIKit automatically dismisses focus.
    ///   - value: The value to match against when determining whether the binding should change.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<Value: Hashable>(
        focus: UIBinding<Value?>, equals value: Value
    ) -> ObservationToken {
        focusToken?.cancel()
        let editingDidBeginAction = NotificationCenter.default.publisher(for: NSTextField.textDidBeginEditingNotification, object: self).sink { _ in
            focus.wrappedValue = value
        }

        let editingDidEndAction = NotificationCenter.default.publisher(for: NSTextField.textDidEndEditingNotification, object: self).sink { _ in
            guard focus.wrappedValue == value else { return }
            focus.wrappedValue = nil
        }

        let innerToken = observe { [weak self] in
            guard let self else { return }
            switch (focus.wrappedValue, currentEditor() != nil) {
            case (value, false):
                becomeFirstResponder()
            case (nil, true):
                window?.makeFirstResponder(nil)
            default:
                break
            }
        }
        let outerToken = ObservationToken {
            editingDidBeginAction.cancel()
            editingDidEndAction.cancel()
            innerToken.cancel()
        }
        focusToken = outerToken
        return outerToken
    }

    /// Binds this text field's focus state to the given Boolean state value.
    ///
    /// Use this method to cause the text field to receive focus whenever the the `condition` value
    /// is `true`. You can use this method to observe the focus state of a text field, or
    /// programmatically set and remove focus from the text field.
    ///
    /// In the following example, a single `UITextField` accepts a user's desired `username`. The
    /// text field binds its focus state to the Boolean value `usernameFieldIsFocused`. A "Submit"
    /// button's action verifies whether the name is available. If the name is unavailable, the
    /// button sets `usernameFieldIsFocused` to `true`, which causes focus to return to the text
    /// field, so the user can enter a different name.
    ///
    /// ```swift
    /// final class LoginViewController: UIViewController {
    ///   @UIBindable private var username = ""
    ///   @UIBindable private var usernameFieldIsFocused = false
    ///
    ///   // ...
    ///
    ///   override func viewDidLoad() {
    ///     super.viewDidLoad()
    ///
    ///     let textField = UITextField(text: $username)
    ///     textField.focus($usernameFieldIsFocused)
    ///
    ///     let submitButton = UIButton(
    ///       style: .system,
    ///       primaryAction: UIAction { [weak self] _ in
    ///         guard let self else { return }
    ///         if !isUserNameAvailable(username: username) {
    ///           usernameFieldIsFocused = true
    ///         }
    ///       }
    ///     )
    ///     submitButton.setTitle("Sign In", for: .normal)
    ///
    ///     // ...
    ///   }
    /// }
    /// ```
    ///
    /// To control focus by matching a value, use the ``UIKit/UITextField/bind(focus:equals:)``
    /// method instead.
    ///
    /// - Parameter condition: The focus state to bind. When focus moves to the text field, the
    ///   binding sets the bound value to `true`. If a caller sets the value to  `true`
    ///   programmatically, then focus moves to the text field. When focus leaves the text field,
    ///   the binding sets the value to `false`. If a caller sets the value to `false`, UIKit
    ///   automatically dismisses focus.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(focus condition: UIBinding<Bool>) -> ObservationToken {
        bind(focus: condition.toOptionalUnit, equals: Bool.Unit())
    }

    private var focusToken: ObservationToken? {
        get { objc_getAssociatedObject(self, Self.focusTokenKey) as? ObservationToken }
        set {
            objc_setAssociatedObject(
                self, Self.focusTokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private static let focusTokenKey = malloc(1)!
}

/// Represents a selection of text.
///
/// Like SwiftUI's `TextSelection`, but for UIKit.
public struct AppKitTextSelection: Hashable, Sendable {
    public var range: Range<String.Index>

    public init(range: Range<String.Index>) {
        self.range = range
    }

    public init(insertionPoint: String.Index) {
        self.range = insertionPoint ..< insertionPoint
    }

    public var isInsertion: Bool {
        range.isEmpty
    }
}
#endif
