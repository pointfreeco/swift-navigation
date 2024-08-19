#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
  import UIKit

  @available(iOS 14, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  extension UISwitch {
    /// Creates a new switch with the specified frame and registers the binding against whether or
    /// not the switch is on.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - isOn: The binding to read from for the current state, and write to when the state
    ///     changes.
    public convenience init(frame: CGRect = .zero, isOn: UIBinding<Bool>) {
      self.init(frame: frame)
      bind(isOn: isOn)
    }

    /// Establishes a two-way connection between a binding and the switch's current state.
    ///
    /// - Parameter isOn: The binding to read from for the current state, and write to when the
    ///   state changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(isOn: UIBinding<Bool>) -> ObserveToken {
      bind(isOn, to: \.isOn, for: .valueChanged) { control, isOn, transaction in
        control.setOn(isOn, animated: !transaction.uiKit.disablesAnimations)
      }
    }
  }
#endif
