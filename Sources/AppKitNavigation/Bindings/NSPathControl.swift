#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSPathControl {
    /// Creates a new path control with the specified frame and registers the binding against the
    /// selected url.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - date: The binding to read from for the selected url, and write to when the selected
    ///     url changes.
    public convenience init(frame: CGRect = .zero, date: UIBinding<URL?>) {
        self.init(frame: frame)
        bind(url: date)
    }

    /// Establishes a two-way connection between a binding and the path control's selected url.
    ///
    /// - Parameter url: The binding to read from for the selected url, and write to when the
    ///   selected url changes.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(url: UIBinding<URL?>) -> ObserveToken {
        bind(url, to: \.url)
    }
}

#endif
