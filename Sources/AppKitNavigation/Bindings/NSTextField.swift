#if canImport(AppKit) && !targetEnvironment(macCatalyst)
public import AppKit
import Combine
public import SwiftNavigation

extension NSTextField {
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
    public func bind(text: UIBinding<String>) -> ObserveToken {
        bind(text, to: \.stringValue)
    }

    /// Establishes a two-way connection between a binding and the text field's current text.
    ///
    /// - Parameter attributedText: The binding to read from for the current text, and write to when
    ///   the attributed text changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(attributedText: UIBinding<NSAttributedString>) -> ObserveToken {
        bind(attributedText, to: \.attributedStringValue)
    }

    /// Establishes a two-way connection between a binding and the text field's current selection.
    ///
    /// - Parameter selection: The binding to read from for the current selection, and write to when
    ///   the selected text range changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(selection: UIBinding<AppKitTextSelection?>) -> ObserveToken {
        // NB: Cancel the previous binding first, so its observers are gone before the new ones
        //     report anything.
        observationTokens[\NSTextField.selectedRange]?.cancel()

        let reportSelection: @MainActor (NSTextField) -> Void = { textField in
            // NB: Applying the binding below moves the selection, which is reported here again;
            //     writing back only what actually changed keeps that from going round forever.
            let textSelection = textField.textSelection
            if selection.wrappedValue != textSelection {
                selection.wrappedValue = textSelection
            }
        }
        let editingChangedAction = NotificationCenter.default
            .publisher(for: NSTextField.textDidChangeNotification, object: self)
            .sink { [weak self] _ in
                guard let self else { return }
                MainActor._assumeIsolated { reportSelection(self) }
            }
        // NB: The field editor reports selection changes to its delegate, which is the text field
        //     being edited. AppKit implements that delegate method on text fields itself, so it
        //     must not be replaced; the notification the field editor posts alongside carries the
        //     same news. One field editor serves every field in a window, hence the delegate check.
        let selectionChangedAction = NotificationCenter.default
            .publisher(for: NSTextView.didChangeSelectionNotification)
            .sink { [weak self] notification in
                guard
                    let self,
                    let fieldEditor = notification.object as? NSTextView,
                    fieldEditor.delegate === self
                else { return }
                MainActor._assumeIsolated { reportSelection(self) }
            }
        let editingDidEndAction = NotificationCenter.default
            .publisher(for: NSTextField.textDidEndEditingNotification, object: self)
            .sink { _ in selection.wrappedValue = nil }
        let token = observe { [weak self] in
            guard let self else { return }
            textSelection = selection.wrappedValue
        }

        let observationToken = ObserveToken {
            editingChangedAction.cancel()
            selectionChangedAction.cancel()
            editingDidEndAction.cancel()
            token.cancel()
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

    // NB: The field editor counts in UTF-16 code units, which differ from 'Character' offsets as
    //     soon as the text holds an emoji or a combining mark, so every conversion goes through
    //     the string's UTF-16 view.
    fileprivate var textSelection: AppKitTextSelection? {
        get {
            guard let textRange = selectedRange else { return nil }
            let text = stringValue
            let utf16Count = text.utf16.count
            let lowerBound = String.Index(utf16Offset: min(textRange.location, utf16Count), in: text)
            let upperBound = String.Index(utf16Offset: min(NSMaxRange(textRange), utf16Count), in: text)
            return AppKitTextSelection(range: lowerBound ..< upperBound)
        }
        set {
            guard let selection = newValue?.range else {
                selectedRange = nil
                return
            }
            let text = stringValue
            let lowerBound = min(selection.lowerBound, text.endIndex)
            let upperBound = min(selection.upperBound, text.endIndex)
            selectedRange = NSRange(
                location: text.utf16.distance(from: text.startIndex, to: lowerBound),
                length: text.utf16.distance(from: lowerBound, to: upperBound)
            )
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
    ) -> ObserveToken {
        focusToken?.cancel()
        // NB: Gaining focus has no notification of its own. The begin-editing notification only
        //     arrives with the first change to the text, not when the field is clicked into or
        //     tabbed to. What does arrive at that moment is a selection change from the field
        //     editor, once it has been set up for this field: the field editor being first
        //     responder, with this field as its delegate, is what it means for the field to have
        //     focus. One field editor serves every field in a window, hence both checks.
        let focusGainedAction = NotificationCenter.default
            .publisher(for: NSTextView.didChangeSelectionNotification)
            .sink { [weak self] notification in
                MainActor._assumeIsolated {
                    guard
                        let self,
                        let fieldEditor = notification.object as? NSTextView,
                        fieldEditor.delegate === self,
                        fieldEditor.window?.firstResponder === fieldEditor,
                        focus.wrappedValue != value
                    else { return }
                    focus.wrappedValue = value
                }
            }

        // NB: Unlike its begin counterpart, this is posted whenever focus leaves the field, edited
        //     or not.
        let editingDidEndAction = NotificationCenter.default.publisher(for: NSTextField.textDidEndEditingNotification, object: self).sink { _ in
            guard focus.wrappedValue == value else { return }
            focus.wrappedValue = nil
        }

        let innerToken = observe { [weak self] in
            guard let self else { return }
            switch (focus.wrappedValue, currentEditor() != nil) {
            case (value, false):
                // NB: The window hands out first-responder status; 'becomeFirstResponder()' only
                //     asks whether the field accepts it and is not meant to be called directly.
                window?.makeFirstResponder(self)
            case (nil, true):
                window?.makeFirstResponder(nil)
            default:
                break
            }
        }
        let outerToken = ObserveToken {
            focusGainedAction.cancel()
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
    public func bind(focus condition: UIBinding<Bool>) -> ObserveToken {
        bind(focus: condition.toOptionalUnit, equals: Bool.Unit())
    }

    private var focusToken: ObserveToken? {
        get { objc_getAssociatedObject(self, Self.focusTokenKey) as? ObserveToken }
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

extension AnyCancellable: @unchecked @retroactive Sendable {}

#endif
