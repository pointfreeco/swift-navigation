#if canImport(AppKit) && !targetEnvironment(macCatalyst)
@_spi(Internals) public import SwiftNavigation
public import AppKit

extension NSOutlineView {
    /// Establishes a two-way connection between a binding and the items the outline has expanded.
    ///
    /// The binding holds the identifiers of the expanded items, and `itemIdentifier` finds the
    /// identifier of the item in a row; a diffable data source has it:
    ///
    /// ```swift
    /// outlineView.bind(
    ///   expandedItems: $model.expandedItems,
    ///   itemIdentifier: dataSource.itemIdentifier(forRow:)
    /// )
    /// ```
    ///
    /// When the binding changes, the outline expands and collapses its items row by row from the
    /// top, so an item whose parent the binding also expands is expanded once its row shows. When
    /// the user expands or collapses an item, its identifier is inserted into the set or removed
    /// from it. Expanding and collapsing for the binding writes nothing back.
    ///
    /// The items are matched again whenever the binding changes, and whenever observable state
    /// that `itemIdentifier` reads changes. Items a diffable data source adds later should carry
    /// their expansion in the snapshot.
    ///
    /// - Parameters:
    ///   - expandedItems: The binding to read from for the expanded items, and write to when the
    ///     user expands or collapses an item.
    ///   - itemIdentifier: The identifier of the item in a row, or `nil` when the row has none.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<ItemIdentifier: Hashable>(
        expandedItems: UIBinding<Set<ItemIdentifier>>,
        itemIdentifier: @escaping (Int) -> ItemIdentifier?
    ) -> ObserveToken {
        unbindExpandedItems()
        let isApplying = LockIsolated(false)
        let token = observe { [weak self] in
            guard let self else { return }
            let identifiersToExpand = expandedItems.wrappedValue
            isApplying.withLock { $0 = true }
            defer { isApplying.withLock { $0 = false } }
            // NB: The row count is read again on every pass: expanding an item shows its children
            //     right below it, which is where the loop goes next.
            var row = 0
            while row < numberOfRows {
                if let item = item(atRow: row), isExpandable(item),
                    let identifier = itemIdentifier(row)
                {
                    let shouldExpand = identifiersToExpand.contains(identifier)
                    if shouldExpand, !isItemExpanded(item) {
                        expandItem(item)
                    } else if !shouldExpand, isItemExpanded(item) {
                        collapseItem(item)
                    }
                }
                row += 1
            }
        }
        let expandObserver = NotificationObserver(
            name: NSOutlineView.itemDidExpandNotification, object: self
        ) { [weak self] notification in
            guard let self, isApplying.withLock({ !$0 }),
                let identifier = identifier(ofItemIn: notification, using: itemIdentifier),
                !expandedItems.wrappedValue.contains(identifier)
            else { return }
            expandedItems.wrappedValue.insert(identifier)
        }
        let collapseObserver = NotificationObserver(
            name: NSOutlineView.itemDidCollapseNotification, object: self
        ) { [weak self] notification in
            guard let self, isApplying.withLock({ !$0 }),
                let identifier = identifier(ofItemIn: notification, using: itemIdentifier),
                expandedItems.wrappedValue.contains(identifier)
            else { return }
            expandedItems.wrappedValue.remove(identifier)
        }
        let observationToken = ObserveToken {
            token.cancel()
            MainActor._assumeIsolated {
                expandObserver.invalidate()
                collapseObserver.invalidate()
            }
        }
        expandedItemsToken = observationToken
        return observationToken
    }

    /// Removes the binding established with
    /// ``AppKit/NSOutlineView/bind(expandedItems:itemIdentifier:)``.
    public func unbindExpandedItems() {
        expandedItemsToken?.cancel()
        expandedItemsToken = nil
    }

    /// The identifier of the item an expansion or a collapse notification is about.
    private func identifier<ItemIdentifier>(
        ofItemIn notification: Notification,
        using itemIdentifier: (Int) -> ItemIdentifier?
    ) -> ItemIdentifier? {
        guard let item = notification.userInfo?["NSObject"] else { return nil }
        let row = row(forItem: item)
        return row >= 0 ? itemIdentifier(row) : nil
    }

    private var expandedItemsToken: ObserveToken? {
        get { objc_getAssociatedObject(self, Self.expandedItemsTokenKey) as? ObserveToken }
        set {
            objc_setAssociatedObject(
                self, Self.expandedItemsTokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private static let expandedItemsTokenKey = malloc(1)!
}
#endif
