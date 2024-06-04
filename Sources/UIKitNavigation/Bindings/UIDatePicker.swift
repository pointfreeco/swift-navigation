#if canImport(UIKit)
  import UIKit

  @available(iOS 14, *)
  extension UIDatePicker {
    /// Creates a new date picker with the specified frame and registers the binding against the
    /// selected date.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - date: The binding to read from for the selected date, and write to when the selected
    ///     date changes.
    public convenience init(frame: CGRect = .zero, date: UIBinding<Date>) {
      self.init(frame: frame)
      bind(date: date)
    }

    /// Establishes a two-way connection between a binding and the date picker's selected date.
    ///
    /// - Parameter date: The binding to read from for the selected date, and write to when the
    ///   selected date changes.
    public func bind(date: UIBinding<Date>) {
      bind(date, to: \.date, for: .valueChanged)
    }
  }
#endif
