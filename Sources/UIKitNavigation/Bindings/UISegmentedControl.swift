#if canImport(UIKit)
  import UIKit
  @_spi(RuntimeWarn) import SwiftUINavigationCore

  @available(iOS 14, *)
  extension UISegmentedControl {
    /// Creates a new color well with the specified frame and registers the binding against the
    /// selected color.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - selectedColor: The binding to read from for the selected color, and write to when the
    ///     selected color is changes.
    public convenience init<Segment: RawRepresentable<Int>>(
      frame: CGRect = .zero, selectedSegment: UIBinding<Segment>
    ) {
      self.init(frame: frame)
      bind(selectedSegment: selectedSegment)
    }

    /// Establishes a two-way connection between a binding and the color well's selected color.
    ///
    /// - Parameter selectedColor: The binding to read from for the selected color, and write to
    ///   when the selected color changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<Segment: RawRepresentable<Int>>(
      selectedSegment: UIBinding<Segment>
    ) -> ObservationToken {
      bind(selectedSegment.toRawValue, to: \.selectedSegmentIndex, for: .valueChanged)
    }
  }

  extension RawRepresentable<Int> {
    fileprivate var toRawValue: Int {
      get { rawValue }
      set {
        guard let rawRepresentable = Self(rawValue: newValue)
        else {
          // TODO: `runtimeWarn`
          return
        }
        self = rawRepresentable
      }
    }
  }
#endif
