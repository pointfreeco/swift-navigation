#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  #if compiler(<6.4)
    // NB: Swift 6.2 treats the delegate's conformance below as public, and a public conformance
    //     needs a public import.
    public import AppKit
  #else
    import AppKit
  #endif
  import AppKitNavigation
  import Testing

  /// A collection view's selected items stay in step with a binding: the collection view follows
  /// the bound identifiers, and writes back what the user, or the app, changes.
  @MainActor
  @Suite struct CollectionViewSelectionBindingTests {
    @Test("a collection view's selected items stay in step with a set")
    func selectedItemsStayInStep() async {
      let (collectionView, dataSource) = makeCollectionView(symbols: ["star", "heart", "bolt"])
      @UIBinding var selectedSymbols: Set<String> = ["heart"]
      collectionView.bind(selection: $selectedSymbols, dataSource: dataSource)
      #expect(collectionView.selectionIndexPaths == [IndexPath(item: 1, section: 0)])

      selectedSymbols = ["star", "bolt"]
      await Task.yield()
      #expect(
        collectionView.selectionIndexPaths
          == [IndexPath(item: 0, section: 0), IndexPath(item: 2, section: 0)]
      )

      // NB: What the collection view does when the user chooses Select All.
      collectionView.selectAll(nil)
      #expect(selectedSymbols == ["star", "heart", "bolt"])

      collectionView.deselectAll(nil)
      #expect(selectedSymbols.isEmpty)
    }

    @Test("a collection view's one selected item stays in step with an optional")
    func selectedItemStaysInStep() async {
      let (collectionView, dataSource) = makeCollectionView(symbols: ["star", "heart"])
      collectionView.allowsMultipleSelection = false
      @UIBinding var selectedSymbol: String? = "heart"
      collectionView.bind(selection: $selectedSymbol, dataSource: dataSource)
      #expect(collectionView.selectionIndexPaths == [IndexPath(item: 1, section: 0)])

      selectedSymbol = nil
      await Task.yield()
      #expect(collectionView.selectionIndexPaths.isEmpty)

      collectionView.selectionIndexPaths = [IndexPath(item: 0, section: 0)]
      #expect(selectedSymbol == "star")
    }

    @Test("an identifier without an item selects nothing and stays in the binding")
    func identifierWithoutAnItemStaysInTheBinding() async {
      let (collectionView, dataSource) = makeCollectionView(symbols: ["star"])
      @UIBinding var selectedSymbols: Set<String> = ["star", "moon"]
      collectionView.bind(selection: $selectedSymbols, dataSource: dataSource)

      #expect(collectionView.selectionIndexPaths == [IndexPath(item: 0, section: 0)])
      #expect(selectedSymbols == ["star", "moon"])
    }

    /// A collection view reports neither through key-value observation nor to its delegate that
    /// a data source update took selected items away.
    @Test("a selected item that a data source update takes away stays in the binding")
    func removedItemStaysInTheBinding() {
      let (collectionView, dataSource) = makeCollectionView(symbols: ["star", "heart"])
      @UIBinding var selectedSymbols: Set<String> = ["star", "heart"]
      collectionView.bind(selection: $selectedSymbols, dataSource: dataSource)

      var snapshot = dataSource.snapshot()
      snapshot.deleteItems(["heart"])
      dataSource.apply(snapshot, animatingDifferences: false)

      #expect(selectedSymbols == ["star", "heart"])
    }

    @Test("the app's delegate keeps getting its messages, including one set after binding")
    func appDelegateKeepsGettingItsMessages() {
      let (collectionView, dataSource) = makeCollectionView(symbols: ["star", "heart"])
      let firstDelegate = SelectionRecordingDelegate()
      collectionView.delegate = firstDelegate
      @UIBinding var selectedSymbols: Set<String> = []
      collectionView.bind(selection: $selectedSymbols, dataSource: dataSource)

      collectionView.selectAll(nil)
      #expect(firstDelegate.selectionCount == 1)
      #expect(selectedSymbols == ["star", "heart"])

      let secondDelegate = SelectionRecordingDelegate()
      collectionView.delegate = secondDelegate
      collectionView.deselectAll(nil)
      #expect(secondDelegate.selectionCount == 1)
      #expect(selectedSymbols.isEmpty)

      collectionView.unbindSelection()
      #expect(collectionView.delegate === secondDelegate)
    }

    @Test("a selected item made again by a reload still shows as selected")
    func reloadedItemStillShowsAsSelected() throws {
      let (collectionView, dataSource) = makeCollectionView(symbols: ["star", "heart"])
      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
        styleMask: [.titled],
        backing: .buffered,
        defer: false
      )
      let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
      scrollView.documentView = collectionView
      window.contentView = scrollView
      collectionView.layoutSubtreeIfNeeded()
      @UIBinding var selectedSymbols: Set<String> = ["heart"]
      collectionView.bind(selection: $selectedSymbols, dataSource: dataSource)

      var snapshot = dataSource.snapshot()
      snapshot.reloadItems(["heart"])
      dataSource.apply(snapshot, animatingDifferences: false)
      collectionView.layoutSubtreeIfNeeded()

      let item = try #require(collectionView.item(at: IndexPath(item: 1, section: 0)))
      #expect(item.isSelected)
      #expect(collectionView.selectionIndexPaths == [IndexPath(item: 1, section: 0)])
      #expect(selectedSymbols == ["heart"])
      withExtendedLifetime(window) {}
    }

    @Test("unbinding a collection view stops writing its selection to the binding")
    func unbindingStopsWritingTheSelection() {
      let (collectionView, dataSource) = makeCollectionView(symbols: ["star", "heart"])
      @UIBinding var selectedSymbols: Set<String> = []
      collectionView.bind(selection: $selectedSymbols, dataSource: dataSource)

      collectionView.unbindSelection()
      collectionView.selectAll(nil)

      #expect(selectedSymbols.isEmpty)
    }

    private func makeCollectionView(
      symbols: [String]
    ) -> (NSCollectionView, NSCollectionViewDiffableDataSource<Int, String>) {
      let collectionView = NSCollectionView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
      let layout = NSCollectionViewFlowLayout()
      layout.itemSize = NSSize(width: 40, height: 40)
      collectionView.collectionViewLayout = layout
      collectionView.isSelectable = true
      collectionView.allowsMultipleSelection = true
      collectionView.register(SymbolItem.self, forItemWithIdentifier: SymbolItem.identifier)
      let dataSource = NSCollectionViewDiffableDataSource<Int, String>(
        collectionView: collectionView
      ) { collectionView, indexPath, _ in
        collectionView.makeItem(withIdentifier: SymbolItem.identifier, for: indexPath)
      }
      var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
      snapshot.appendSections([0])
      snapshot.appendItems(symbols, toSection: 0)
      dataSource.apply(snapshot, animatingDifferences: false)
      return (collectionView, dataSource)
    }
  }

  private final class SelectionRecordingDelegate: NSObject, NSCollectionViewDelegate {
    private(set) var selectionCount = 0

    func collectionView(
      _ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>
    ) {
      selectionCount += 1
    }

    func collectionView(
      _ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>
    ) {
      selectionCount += 1
    }
  }

  private final class SymbolItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("SymbolItem")

    override func loadView() {
      view = NSView()
    }
  }
#endif
