#if canImport(AppKit) && !targetEnvironment(macCatalyst)
public import AppKit

// NB: Unlike the views and view controllers it describes, a split view item is not isolated to the
//     main actor, but bindings are.
@MainActor
extension NSSplitViewItem {
    /// Establishes a two-way connection between a binding and whether the split view item is
    /// collapsed.
    ///
    /// When the user collapses or expands the item — by dragging its divider, or with a sidebar
    /// or inspector toggle — the change is written back to the binding. A change to the binding
    /// made with an animation, inside ``withAppKitAnimation(_:_:completion:)`` or through a
    /// binding's own transaction, collapses or expands the item with that animation; any other
    /// change applies at once.
    ///
    /// ```swift
    /// inspectorItem.bind(isCollapsed: $model.isInspectorCollapsed)
    ///
    /// withAppKitAnimation(.easeInOut(duration: 0.2)) {
    ///   model.isInspectorCollapsed.toggle()
    /// }
    /// ```
    ///
    /// - Parameter isCollapsed: The binding to read from for whether the item is collapsed, and
    ///   write to when the user collapses or expands it.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind(isCollapsed: UIBinding<Bool>) -> ObserveToken {
        // NB: No target-action pair: AppKit reports the user's changes through key-value
        //     observation, which the documentation of 'collapsed' promises.
        establishBinding(isCollapsed, to: \.isCollapsed, of: self, through: nil) {
            splitViewItem, isCollapsed, transaction in
            guard splitViewItem.isCollapsed != isCollapsed else { return }
            if let animation = transaction.appKit.animation,
                !transaction.appKit.disablesAnimations
            {
                // NB: Collapsing animates only through the animator proxy. The animation runs
                //     here rather than relying on the one 'observe' sets up, since a binding's own
                //     transaction arrives without it.
                animation.perform {
                    splitViewItem.animator().isCollapsed = isCollapsed
                }
            } else {
                splitViewItem.isCollapsed = isCollapsed
            }
        }
    }

    /// Removes the binding established with ``AppKit/NSSplitViewItem/bind(isCollapsed:)``.
    public func unbindIsCollapsed() {
        removeBinding(to: \NSSplitViewItem.isCollapsed)
    }
}
#endif
