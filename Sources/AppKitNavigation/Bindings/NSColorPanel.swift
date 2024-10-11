#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSColorPanel: NSTargetActionProtocol {
    public var appkitNavigationTarget: AnyObject? {
        set { setTarget(newValue) }
        get { value(forKeyPath: "target") as? AnyObject }
    }

    public var appkitNavigationAction: Selector? {
        set { setAction(newValue) }
        get { value(forKeyPath: "action") as? Selector }
    }
}

extension NSColorPanel {
    /// Creates a new color panel and registers the binding against the
    /// selected color.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - color: The binding to read from for the selected color, and write to when the
    ///     selected color is changes.
    public convenience init(color: UIBinding<NSColor>) {
        self.init()
        bind(color: color)
    }

    /// Establishes a two-way connection between a binding and the color panel's selected color.
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
