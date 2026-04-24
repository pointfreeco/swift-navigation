#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSColorWell {
    /// Creates a new color well with the specified frame and registers the binding against the
    /// selected color.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - color: The binding to read from for the selected color, and write to when the
    ///     selected color is changes.
    public convenience init(frame: CGRect = .zero, color: UIBinding<NSColor>) {
        self.init(frame: frame)
        bind(color: color)
    }

    /// Establishes a two-way connection between a binding and the color well's selected color.
    ///
    /// - Parameter color: The binding to read from for the selected color, and write to
    ///   when the selected color changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(color: UIBinding<NSColor>) -> ObserveToken {
        bind(color, to: \.color)
    }
}
#endif
