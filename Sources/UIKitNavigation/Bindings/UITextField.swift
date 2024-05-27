import UIKit

@available(iOS 14, *)
extension UITextField {
  /// Creates a new text field with the specified frame and registers the binding against its text.
  ///
  /// - Parameters:
  ///   - frame: The frame rectangle for the view, measured in points.
  ///   - value: The binding to read from for the current text, and write to when the text changes.
  public convenience init(frame: CGRect = .zero, text: UIBinding<String>) {
    self.init(frame: frame)
    bind(text: text)
  }

  /// Establishes a two-way connection between a binding and the text field's current text.
  ///
  /// - Parameter value: The binding to read from for the current text, and write to when the text
  ///   changes.
  public func bind(text: UIBinding<String>) {
    bind(UIBinding(text), to: \.text, for: .editingChanged)
  }
}
