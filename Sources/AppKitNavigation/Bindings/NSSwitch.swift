#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSSwitch {
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
        bind(isOn, to: \.boolValue) { control, isOn, transaction in
            control.boolValue = isOn
        }
    }

    @objc var boolValue: Bool {
        set { state = newValue ? .on : .off }
        get { state == .on }
    }
}
#endif
