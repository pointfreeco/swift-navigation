import UIKit

@available(iOS 14, *)
extension UIColorWell {
  /// Creates a new color well with the specified frame and registers the binding against the
  /// selected color.
  ///
  /// - Parameters:
  ///   - frame: The frame rectangle for the view, measured in points.
  ///   - selectedColor: The binding to read from for the selected color, and write to when the
  ///     selected color is changes.
  public convenience init(frame: CGRect = .zero, selectedColor: UIBinding<UIColor?>) {
    self.init(frame: frame)
    bind(selectedColor: selectedColor)
  }

  /// Establishes a two-way connection between a binding and the color well's selected color.
  ///
  /// - Parameter selectedColor: The binding to read from for the selected color, and write to when
  ///   the selected color changes.
  public func bind(selectedColor: UIBinding<UIColor?>) {
    bind(selectedColor, to: \.selectedColor, for: .valueChanged)
  }
}
