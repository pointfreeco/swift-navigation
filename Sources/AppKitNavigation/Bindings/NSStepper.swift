#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSStepper {
    /// Creates a new stepper with the specified frame and registers the binding against the value.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - value: The binding to read from for the current value, and write to when the value
    ///     changes.
    public convenience init(frame: CGRect = .zero, value: UIBinding<Double>) {
        self.init(frame: frame)
        bind(value: value)
    }

    /// Establishes a two-way connection between a binding and the stepper's current value.
    ///
    /// - Parameter value: The binding to read from for the current value, and write to when the
    ///   value changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(value: UIBinding<Double>) -> ObserveToken {
        bind(value, to: \.doubleValue)
    }
}
#endif
