#if canImport(AppKit) && !targetEnvironment(macCatalyst) && AppKitPlus
  import AppKit
  import AppKitNavigation
  import AppKitPlus
  import Testing

  /// Tables and outlines driven by AppKitPlus's diffable data sources bind their selected row the
  /// same way as with AppKit's own.
  @MainActor
  @Suite struct AppKitPlusDataSourceBindingTests {
    @Test("a table with a reorderable data source keeps its selection in step")
    func reorderableTableSelectionStaysInStep() async {
      let tableView = NSTableView()
      tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Track")))
      let dataSource = NSTableViewDiffableReorderableDataSource<Int, String>(tableView: tableView) {
        _, _, _, track in
        NSTextField(labelWithString: track)
      }
      var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
      snapshot.appendSections([0])
      snapshot.appendItems(["Intro", "Verse", "Chorus"])
      dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
      @UIBinding var selectedTrack: String? = "Verse"

      tableView.bind(selection: $selectedTrack, dataSource: dataSource)
      #expect(tableView.selectedRow == 1)

      selectedTrack = "Chorus"
      await Task.yield()
      #expect(tableView.selectedRow == 2)

      // NB: What the table does when the user clicks a row.
      tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
      #expect(selectedTrack == "Intro")
    }

    @Test("an outline with an AppKitPlus data source keeps its selection in step")
    func outlineSelectionStaysInStep() async {
      let (outlineView, dataSource) = makeOutline()
      @UIBinding var selectedItem: String? = "Fruit"

      outlineView.bind(selection: $selectedItem, dataSource: dataSource)
      #expect(outlineView.selectedRow == 0)

      selectedItem = "Vegetables"
      await Task.yield()
      #expect(outlineView.selectedRow == 1)

      outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
      #expect(selectedItem == "Fruit")
    }

    @Test("an item inside a collapsed group selects nothing and stays in the binding")
    func itemInsideACollapsedGroupStaysInTheBinding() {
      let (outlineView, dataSource) = makeOutline()
      @UIBinding var selectedItem: String? = "Cherries"

      outlineView.bind(selection: $selectedItem, dataSource: dataSource)

      #expect(outlineView.selectedRow == -1)
      #expect(selectedItem == "Cherries")
    }

    private func makeOutline() -> (NSOutlineView, NSOutlineViewDiffableDataSource<String>) {
      let outlineView = NSOutlineView()
      let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Item"))
      outlineView.addTableColumn(column)
      outlineView.outlineTableColumn = column
      let dataSource = NSOutlineViewDiffableDataSource<String>(outlineView: outlineView) {
        _, _, _, item in
        NSTextField(labelWithString: item)
      }
      var snapshot = NSDiffableDataSourceSectionSnapshot<String>()
      snapshot.append(["Fruit", "Vegetables"])
      snapshot.append(["Apples", "Cherries"], to: "Fruit")
      dataSource.apply(snapshot, animatingDifferences: false)
      return (outlineView, dataSource)
    }
  }
#endif
