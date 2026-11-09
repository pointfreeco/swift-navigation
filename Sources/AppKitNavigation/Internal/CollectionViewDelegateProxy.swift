#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  public import AppKit

  /// Stands in as a collection view's delegate while a selection binding is in place, so that the
  /// binding hears of the user's selection changes, and passes every message on to the delegate
  /// the app set.
  ///
  /// A collection view reports the user's clicks, Select All and Deselect All only to its
  /// delegate: neither key-value observation of `selectionIndexPaths` nor a notification carries
  /// them.
  @MainActor
  final class CollectionViewDelegateProxy: NSObject, NSCollectionViewDelegate {
    // NB: Read by the Objective-C runtime's forwarding, which is not isolated. The collection view
    //     only messages its delegate on the main thread.
    nonisolated(unsafe) weak var forwardDelegate: (any NSCollectionViewDelegate)?

    /// Runs when the user selects or deselects items.
    var selectionDidChange: (() -> Void)?

    /// Runs when the collection view is about to show an item.
    var itemWillDisplay: ((NSCollectionViewItem, IndexPath) -> Void)?

    /// Puts the proxy back in front when the app sets another delegate.
    var delegateObservation: NSKeyValueObservation?

    nonisolated override func responds(to selector: Selector!) -> Bool {
      super.responds(to: selector) || (forwardDelegate?.responds(to: selector) ?? false)
    }

    nonisolated override func forwardingTarget(for selector: Selector!) -> Any? {
      forwardDelegate
    }

    func collectionView(
      _ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>
    ) {
      forwardDelegate?.collectionView?(collectionView, didSelectItemsAt: indexPaths)
      selectionDidChange?()
    }

    func collectionView(
      _ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>
    ) {
      forwardDelegate?.collectionView?(collectionView, didDeselectItemsAt: indexPaths)
      selectionDidChange?()
    }

    func collectionView(
      _ collectionView: NSCollectionView,
      willDisplay item: NSCollectionViewItem,
      forRepresentedObjectAt indexPath: IndexPath
    ) {
      itemWillDisplay?(item, indexPath)
      forwardDelegate?.collectionView?(
        collectionView, willDisplay: item, forRepresentedObjectAt: indexPath
      )
    }
  }
#endif
