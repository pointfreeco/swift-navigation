#if canImport(UIKit)
  import UIKit

  @available(iOS 14, *)
  extension UITextField {
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
    public func bind(text: UIBinding<String>) {
      bind(UIBinding(text), to: \.text, for: .editingChanged)
    }

    /// Establishes a two-way connection between a binding and the text field's current text.
    ///
    /// - Parameter attributedText: The binding to read from for the current text, and write to when
    ///   the attributed text changes.
    public func bind(attributedText: UIBinding<NSAttributedString>) {
      bind(UIBinding(attributedText), to: \.attributedText, for: .editingChanged)
    }
  }
#endif
