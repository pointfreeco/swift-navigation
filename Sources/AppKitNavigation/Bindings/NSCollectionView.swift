#if canImport(AppKit) && !targetEnvironment(macCatalyst)
public import AppKit

extension NSCollectionView {
    /// Establishes a two-way connection between a binding and the items the collection view has
    /// selected.
    ///
    /// The binding holds the identifiers of the selected items, and two functions translate
    /// between identifiers and index paths. A diffable data source has both, which
    /// ``AppKit/NSCollectionView/bind(selection:dataSource:)-(UIBinding<Set<ItemIdentifier>>,_)``
    /// passes for you.
    ///
    /// When the binding changes, the collection view selects the identifiers' items; identifiers
    /// without an index path are skipped, and stay in the binding. When the user changes the
    /// selection — clicks, extends it, drags a rubber band, uses the arrow keys, or chooses Select
    /// All — or the app sets `selectionIndexPaths`, the identifiers of the selected items are
    /// written back. Changes the binding itself made are not.
    ///
    /// A collection view reports the user's selection changes only to its delegate, so the
    /// binding puts a proxy in front of the delegate you set. The proxy passes every message on
    /// to your delegate, and the binding puts it back in front if you set another delegate later;
    /// reading `delegate` returns the proxy. Removing the binding restores your delegate.
    ///
    /// The collection view says nothing when a data source update takes selected items away, or
    /// when a reload deselects the items it makes again. Their identifiers stay in the binding,
    /// and the binding selects their items again as they come on screen.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected items, and write to when the
    ///     selection changes.
    ///   - indexPath: The index path of the item with an identifier, or `nil` when there is none.
    ///   - itemIdentifier: The identifier of the item at an index path, or `nil` when it has none.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<ItemIdentifier: Hashable>(
        selection: UIBinding<Set<ItemIdentifier>>,
        indexPath: @escaping (ItemIdentifier) -> IndexPath?,
        itemIdentifier: @escaping (IndexPath) -> ItemIdentifier?
    ) -> ObserveToken {
        bindSelectedItems(
            read: { selection.wrappedValue },
            write: { identifiers in selection.wrappedValue = Set(identifiers) },
            indexPath: indexPath,
            itemIdentifier: itemIdentifier
        )
    }

    /// Establishes a two-way connection between a binding and the one item the collection view has
    /// selected.
    ///
    /// Works as
    /// ``AppKit/NSCollectionView/bind(selection:indexPath:itemIdentifier:)-(UIBinding<Set<ItemIdentifier>>,_,_)``
    /// does for a set. When several items are selected, the binding holds the first of them.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected item, and write to when the
    ///     selection changes.
    ///   - indexPath: The index path of the item with an identifier, or `nil` when there is none.
    ///   - itemIdentifier: The identifier of the item at an index path, or `nil` when it has none.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<ItemIdentifier: Hashable>(
        selection: UIBinding<ItemIdentifier?>,
        indexPath: @escaping (ItemIdentifier) -> IndexPath?,
        itemIdentifier: @escaping (IndexPath) -> ItemIdentifier?
    ) -> ObserveToken {
        bindSelectedItems(
            read: { selection.wrappedValue.map { [$0] } ?? [] },
            write: { identifiers in selection.wrappedValue = identifiers.first },
            indexPath: indexPath,
            itemIdentifier: itemIdentifier
        )
    }

    /// Establishes a two-way connection between a binding and the items the collection view has
    /// selected, through the lookups of the collection view's diffable data source.
    ///
    /// ```swift
    /// collectionView.bind(selection: $model.selectedSymbolIDs, dataSource: dataSource)
    /// ```
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected items, and write to when the
    ///     selection changes.
    ///   - dataSource: The collection view's diffable data source.
    /// - Returns: A cancel token.
    @discardableResult
    @available(macOS 10.15.1, *)
    public func bind<SectionIdentifier, ItemIdentifier>(
        selection: UIBinding<Set<ItemIdentifier>>,
        dataSource: NSCollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
    ) -> ObserveToken {
        // NB: Held weakly: the collection view keeps this binding for as long as it lives, and the
        //     data source may hold on to the collection view.
        bind(
            selection: selection,
            indexPath: { [weak dataSource] identifier in dataSource?.indexPath(for: identifier) },
            itemIdentifier: { [weak dataSource] indexPath in dataSource?.itemIdentifier(for: indexPath) }
        )
    }

    /// Establishes a two-way connection between a binding and the one item the collection view has
    /// selected, through the lookups of the collection view's diffable data source.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected item, and write to when the
    ///     selection changes.
    ///   - dataSource: The collection view's diffable data source.
    /// - Returns: A cancel token.
    @discardableResult
    @available(macOS 10.15.1, *)
    public func bind<SectionIdentifier, ItemIdentifier>(
        selection: UIBinding<ItemIdentifier?>,
        dataSource: NSCollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
    ) -> ObserveToken {
        bind(
            selection: selection,
            indexPath: { [weak dataSource] identifier in dataSource?.indexPath(for: identifier) },
            itemIdentifier: { [weak dataSource] indexPath in dataSource?.itemIdentifier(for: indexPath) }
        )
    }

    /// Removes a binding established with one of the collection view's `bind(selection:…)`
    /// methods.
    public func unbindSelection() {
        removeBinding(to: \NSCollectionView.selectionIndexPaths)
    }

    private func bindSelectedItems<ItemIdentifier: Hashable>(
        read: @escaping () -> Set<ItemIdentifier>,
        write: @escaping (_ identifiersInOrder: [ItemIdentifier]) -> Void,
        indexPath: @escaping (ItemIdentifier) -> IndexPath?,
        itemIdentifier: @escaping (IndexPath) -> ItemIdentifier?
    ) -> ObserveToken {
        unbindSelection()
        let isSelecting = LockIsolated(false)
        let token = observe { [weak self] in
            guard let self else { return }
            let indexPathsToSelect = Set(read().compactMap(indexPath))
            isSelecting.withLock { $0 = true }
            defer { isSelecting.withLock { $0 = false } }
            if selectionIndexPaths != indexPathsToSelect {
                selectionIndexPaths = indexPathsToSelect
            }
            showSelectionOfVisibleItems()
        }
        let writeSelectionBack = { [weak self] in
            guard let self, isSelecting.withLock({ !$0 }) else { return }
            let identifiers = selectionIndexPaths.sorted().compactMap(itemIdentifier)
            guard read() != Set(identifiers) else { return }
            write(identifiers)
        }
        let delegateProxy = installDelegateProxy()
        delegateProxy.selectionDidChange = writeSelectionBack
        // NB: A reload deselects the items it makes again, and says nothing about it. An item
        //     whose identifier is still bound is selected again as it comes on screen.
        delegateProxy.itemWillDisplay = { [weak self] item, displayedIndexPath in
            guard
                let self,
                let identifier = itemIdentifier(displayedIndexPath),
                read().contains(identifier)
            else { return }
            if !selectionIndexPaths.contains(displayedIndexPath) {
                isSelecting.withLock { $0 = true }
                defer { isSelecting.withLock { $0 = false } }
                selectionIndexPaths.insert(displayedIndexPath)
            }
            item.isSelected = true
        }
        // NB: Setting 'selectionIndexPaths', and moving the selection with the arrow keys, are
        //     reported through key-value observation rather than to the delegate.
        nonisolated(unsafe) let writeSelectionBackFromObservation = writeSelectionBack
        let observation = observe(\.selectionIndexPaths) { _, _ in
            MainActor._assumeIsolated {
                writeSelectionBackFromObservation()
            }
        }
        let observationToken = ObserveToken { [weak self, weak delegateProxy] in
            token.cancel()
            observation.invalidate()
            MainActor._assumeIsolated {
                guard let self, let delegateProxy else { return }
                self.removeDelegateProxy(delegateProxy)
            }
        }
        observationTokens[\NSCollectionView.selectionIndexPaths] = observationToken
        return observationToken
    }

    /// The proxy in front of the delegate the app set, while a selection binding is in place.
    fileprivate var appKitNavigationDelegateProxy: CollectionViewDelegateProxy? {
        get {
            objc_getAssociatedObject(self, delegateProxyKey) as? CollectionViewDelegateProxy
        }
        set {
            objc_setAssociatedObject(self, delegateProxyKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Puts a proxy in front of the collection view's delegate, and keeps it in front when the
    /// app sets another delegate.
    private func installDelegateProxy() -> CollectionViewDelegateProxy {
        let delegateProxy = CollectionViewDelegateProxy()
        delegateProxy.forwardDelegate = delegate
        // NB: The collection view holds its delegate weakly.
        appKitNavigationDelegateProxy = delegateProxy
        delegate = delegateProxy
        delegateProxy.delegateObservation = observe(\.delegate) { collectionView, _ in
            MainActor._assumeIsolated {
                guard
                    let delegateProxy = collectionView.appKitNavigationDelegateProxy,
                    (collectionView.delegate as AnyObject?) !== delegateProxy
                else { return }
                delegateProxy.forwardDelegate = collectionView.delegate
                // NB: Set again, so that the collection view asks the proxy afresh which
                //     messages it answers.
                collectionView.delegate = delegateProxy
            }
        }
        return delegateProxy
    }

    /// Takes the proxy away and gives the app's delegate back its place.
    private func removeDelegateProxy(_ delegateProxy: CollectionViewDelegateProxy) {
        delegateProxy.delegateObservation?.invalidate()
        delegateProxy.delegateObservation = nil
        delegateProxy.selectionDidChange = nil
        delegateProxy.itemWillDisplay = nil
        if (delegate as AnyObject?) === delegateProxy {
            delegate = delegateProxy.forwardDelegate
        }
        if appKitNavigationDelegateProxy === delegateProxy {
            appKitNavigationDelegateProxy = nil
        }
    }

    /// Marks the visible items at selected index paths as selected.
    ///
    /// A reload hands the selected index paths freshly made items, which come back unselected,
    /// while the selection itself stays the same, so assigning it again would change nothing.
    private func showSelectionOfVisibleItems() {
        let selectedIndexPaths = selectionIndexPaths
        for visibleIndexPath in indexPathsForVisibleItems() where selectedIndexPaths.contains(visibleIndexPath) {
            item(at: visibleIndexPath)?.isSelected = true
        }
    }
}

@MainActor
private let delegateProxyKey = malloc(1)!
#endif
