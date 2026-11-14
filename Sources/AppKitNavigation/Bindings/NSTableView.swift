#if canImport(AppKit) && !targetEnvironment(macCatalyst)
@_spi(Internals) public import SwiftNavigation
public import AppKit

extension NSTableView {
    /// Establishes a two-way connection between a binding and the table's selected row.
    ///
    /// The binding holds the identifier of the selected item, and two functions translate between
    /// identifiers and rows. A diffable data source has both:
    ///
    /// ```swift
    /// outlineView.bind(
    ///   selection: $model.selectedItem,
    ///   row: dataSource.row(forItemIdentifier:),
    ///   itemIdentifier: dataSource.itemIdentifier(forRow:)
    /// )
    /// ```
    ///
    /// When the binding changes, the table selects the identifier's row, or no row if `row` finds
    /// none. When the selection changes otherwise — the user clicks or uses the keyboard, or the
    /// selected row goes away — the selected row's identifier is written back, and `nil` when no
    /// row is selected. Selecting a row for the binding writes nothing back, so the binding and the
    /// table never echo each other.
    ///
    /// The selection is matched again whenever the binding changes, and whenever observable state
    /// that `row` reads changes: look rows up in an observable model to have the selection follow
    /// a reload. A diffable data source's snapshots keep the selection on the same items already.
    ///
    /// This binds a single selection; outline views bind theirs the same way.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected item, and write to when the
    ///     selection changes.
    ///   - row: The row of an item, or `nil` (or a negative row) when it has none.
    ///   - itemIdentifier: The identifier of the item in a row, or `nil` when the row has none.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<ItemIdentifier: Hashable>(
        selection: UIBinding<ItemIdentifier?>,
        row: @escaping (ItemIdentifier) -> Int?,
        itemIdentifier: @escaping (Int) -> ItemIdentifier?
    ) -> ObserveToken {
        unbindSelection()
        let isSelecting = LockIsolated(false)
        let token = observe { [weak self] in
            guard let self else { return }
            var rowsToSelect = IndexSet()
            if let identifier = selection.wrappedValue, let row = row(identifier), row >= 0 {
                rowsToSelect.insert(row)
            }
            guard selectedRowIndexes != rowsToSelect else { return }
            isSelecting.withLock { $0 = true }
            defer { isSelecting.withLock { $0 = false } }
            selectRowIndexes(rowsToSelect, byExtendingSelection: false)
        }
        // NB: An outline view posts its own notification instead of the table's.
        let notificationName =
            self is NSOutlineView
            ? NSOutlineView.selectionDidChangeNotification
            : NSTableView.selectionDidChangeNotification
        let observer = NotificationObserver(name: notificationName, object: self) {
            [weak self] _ in
            guard let self, isSelecting.withLock({ !$0 }) else { return }
            let identifier = selectedRow >= 0 ? itemIdentifier(selectedRow) : nil
            guard selection.wrappedValue != identifier else { return }
            selection.wrappedValue = identifier
        }
        let observationToken = ObserveToken {
            token.cancel()
            MainActor._assumeIsolated {
                observer.invalidate()
            }
        }
        observationTokens[\NSTableView.selectedRowIndexes] = observationToken
        return observationToken
    }

    /// Establishes a two-way connection between a binding and the table's selected row, through
    /// the row lookups of the table's diffable data source.
    ///
    /// ```swift
    /// tableView.bind(selection: $model.selectedApplicationID, dataSource: dataSource)
    /// ```
    ///
    /// See ``AppKit/NSTableView/bind(selection:row:itemIdentifier:)`` for how the binding and the
    /// selection follow each other.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected item, and write to when the
    ///     selection changes.
    ///   - dataSource: The table's diffable data source.
    /// - Returns: A cancel token.
    // NB: The manifests for Swift 6.2 and earlier support macOS releases before diffable data
    //     sources.
    @available(macOS 11, *)
    @discardableResult
    public func bind<SectionIdentifier, ItemIdentifier>(
        selection: UIBinding<ItemIdentifier?>,
        dataSource: NSTableViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
    ) -> ObserveToken {
        // NB: Held weakly: the table keeps this binding for as long as it lives, and the data
        //     source may hold on to the table.
        bind(
            selection: selection,
            row: { [weak dataSource] identifier in dataSource?.row(forItemIdentifier: identifier) },
            itemIdentifier: { [weak dataSource] row in dataSource?.itemIdentifier(forRow: row) }
        )
    }

    /// Removes the binding established with
    /// ``AppKit/NSTableView/bind(selection:row:itemIdentifier:)`` or
    /// ``AppKit/NSTableView/bind(selection:dataSource:)-(_,NSTableViewDiffableDataSource<SectionIdentifier,ItemIdentifier>)``.
    public func unbindSelection() {
        removeBinding(to: \NSTableView.selectedRowIndexes)
    }
}
#endif
