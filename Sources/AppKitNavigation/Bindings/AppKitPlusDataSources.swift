#if canImport(AppKit) && !targetEnvironment(macCatalyst) && AppKitPlus
  public import AppKit
  public import AppKitPlus
  public import SwiftNavigation

  extension NSTableView {
    /// Establishes a two-way connection between a binding and the table's selected row, through
    /// the row lookups of an AppKitPlus reorderable diffable data source.
    ///
    /// ```swift
    /// tableView.bind(selection: $model.selectedTrackID, dataSource: dataSource)
    /// ```
    ///
    /// Works as ``AppKit/NSTableView/bind(selection:row:itemIdentifier:)``.
    ///
    /// Available with the `AppKitPlus` package trait.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected item, and write to when the
    ///     selection changes.
    ///   - dataSource: The table's reorderable diffable data source.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<SectionIdentifier: Hashable & Sendable, ItemIdentifier: Hashable & Sendable>(
      selection: UIBinding<ItemIdentifier?>,
      dataSource: NSTableViewDiffableReorderableDataSource<SectionIdentifier, ItemIdentifier>
    ) -> ObserveToken {
      // NB: Held weakly: the table keeps this binding for as long as it lives, and the data source
      //     may hold on to the table.
      bind(
        selection: selection,
        row: { [weak dataSource] identifier in dataSource?.row(forItemIdentifier: identifier) },
        itemIdentifier: { [weak dataSource] row in dataSource?.itemIdentifier(forRow: row) }
      )
    }
  }

  extension NSOutlineView {
    /// Establishes a two-way connection between a binding and the outline's selected row, through
    /// the row lookups of an AppKitPlus outline diffable data source.
    ///
    /// ```swift
    /// outlineView.bind(selection: $model.selectedEntityID, dataSource: dataSource)
    /// ```
    ///
    /// Works as ``AppKit/NSTableView/bind(selection:row:itemIdentifier:)``. An item inside a
    /// collapsed group has no row, so the outline selects nothing for it, and the identifier stays
    /// in the binding.
    ///
    /// Available with the `AppKitPlus` package trait.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected item, and write to when the
    ///     selection changes.
    ///   - dataSource: The outline's diffable data source.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<ItemIdentifier: Hashable & Sendable>(
      selection: UIBinding<ItemIdentifier?>,
      dataSource: NSOutlineViewDiffableDataSource<ItemIdentifier>
    ) -> ObserveToken {
      bind(
        selection: selection,
        row: { [weak dataSource] identifier in
          // NB: AppKitPlus answers -1, not nil, for an item that has no row.
          guard let row = dataSource?.row(forItemIdentifier: identifier), row >= 0 else {
            return nil
          }
          return row
        },
        itemIdentifier: { [weak dataSource] row in dataSource?.itemIdentifier(forRow: row) }
      )
    }
  }
#endif
