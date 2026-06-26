#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
  public import SwiftNavigation
  public import UIKit

  @available(iOS 14, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  extension UISlider {
    /// Creates a new slider with the specified frame and registers the binding against the value.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - value: The binding to read from for the current value, and write to when the value
    ///     changes.
    #if !Perception
      @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    #endif
    public convenience init(frame: CGRect = .zero, value: UIBinding<Float>) {
      self.init(frame: frame)
      bind(value: value)
    }

    /// Establishes a two-way connection between a binding and the slider's current value.
    ///
    /// - Parameter value: The binding to read from for the current value, and write to when the
    ///   value changes.
    /// - Returns: A cancel token.
    #if !Perception
      @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    #endif
    @discardableResult
    public func bind(value: UIBinding<Float>) -> ObserveToken {
      bind(value, to: \.value, for: .valueChanged)
    }
  }
#endif
