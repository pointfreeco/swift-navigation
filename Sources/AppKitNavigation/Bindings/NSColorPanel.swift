#if canImport(AppKit) && !targetEnvironment(macCatalyst)

public import AppKit

extension NSColorPanel: @unchecked @retroactive Sendable {}
extension NSColorPanel: TargetActionProtocol {
    public var target: AnyObject? {
        set { setTarget(newValue) }
        get { value(forKeyPath: "target") as? AnyObject }
    }

    public var action: Selector? {
        set { setAction(newValue) }
        get {
            // NB: The SDK declares no getter for the panel's action, and key-value coding cannot
            //     return a selector: asking it for "action" raises an exception. AppKit implements
            //     the getter all the same (every release checked, macOS 12 through 27, has it), so
            //     it is called directly, and a panel without one reports no action rather than
            //     crashing. The target is an object, which key-value coding returns just fine.
            let getter = NSSelectorFromString("action")
            guard responds(to: getter) else { return nil }
            typealias ActionGetter = @convention(c) (NSColorPanel, Selector) -> Selector?
            return unsafeBitCast(method(for: getter), to: ActionGetter.self)(self, getter)
        }
    }
}

extension NSColorPanel {
    /// Creates a new color panel and registers the binding against the
    /// selected color.
    ///
    /// - Parameter color: The binding to read from for the selected color, and write to when the
    ///   selected color changes.
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
