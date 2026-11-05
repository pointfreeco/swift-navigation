#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
  import AppKitNavigation
  import Testing

  /// A table's or an outline's selected row, and an outline's expanded items, stay in step with a
  /// binding: the view follows the bound value, and writes back what the user changes, but not
  /// what the binding itself changed.
  @MainActor
  @Suite struct TableSelectionBindingTests {
    // MARK: - Selection

    @Test("a table view's selection stays in step with its binding")
    func tableViewSelectionStaysInStep() async {
      let categories = ["Colors", "Shapes", "Weather"]
      let rowCount = RowCount(categories.count)
      let tableView = makeTableView(dataSource: rowCount)
      @UIBinding var selectedCategory: String? = "Shapes"
      tableView.bind(
        selection: $selectedCategory,
        row: { category in categories.firstIndex(of: category) },
        itemIdentifier: { row in categories[row] }
      )
      #expect(tableView.selectedRow == 1)

      selectedCategory = "Weather"
      await Task.yield()
      #expect(tableView.selectedRow == 2)

      // NB: What the table does when the user clicks a row.
      tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
      #expect(selectedCategory == "Colors")
    }

    @Test("a table view with no selected row writes nil to its binding")
    func clearingTheSelectionWritesNil() {
      let categories = ["Colors", "Shapes"]
      let rowCount = RowCount(categories.count)
      let tableView = makeTableView(dataSource: rowCount)
      @UIBinding var selectedCategory: String? = "Shapes"
      tableView.bind(
        selection: $selectedCategory,
        row: { category in categories.firstIndex(of: category) },
        itemIdentifier: { row in categories[row] }
      )

      tableView.deselectAll(nil)

      #expect(selectedCategory == nil)
    }

    @Test("an identifier with no visible row deselects the table and stays in the binding")
    func identifierWithoutARowDeselectsTheTable() async {
      let categories = ["Colors", "Shapes"]
      let rowCount = RowCount(categories.count)
      let tableView = makeTableView(dataSource: rowCount)
      @UIBinding var selectedCategory: String? = "Shapes"
      tableView.bind(
        selection: $selectedCategory,
        row: { category in categories.firstIndex(of: category) },
        itemIdentifier: { row in categories[row] }
      )

      selectedCategory = "Hidden"
      await Task.yield()

      #expect(tableView.selectedRow == -1)
      #expect(selectedCategory == "Hidden")
    }

    @Test("unbinding a table view's selection stops writing to the binding")
    func unbindingTheSelectionStopsWriting() {
      let categories = ["Colors", "Shapes"]
      let rowCount = RowCount(categories.count)
      let tableView = makeTableView(dataSource: rowCount)
      @UIBinding var selectedCategory: String? = "Shapes"
      tableView.bind(
        selection: $selectedCategory,
        row: { category in categories.firstIndex(of: category) },
        itemIdentifier: { row in categories[row] }
      )

      tableView.unbindSelection()
      tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)

      #expect(selectedCategory == "Shapes")
    }

    @Test("a table view's selection stays in step through its diffable data source")
    func selectionThroughADiffableDataSource() {
      let tableView = NSTableView()
      tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column")))
      let dataSource = NSTableViewDiffableDataSource<Int, String>(tableView: tableView) {
        _, _, _, _ in NSView()
      }
      retain(dataSource, by: tableView)
      var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
      snapshot.appendSections([0])
      snapshot.appendItems(["Colors", "Shapes", "Weather"])
      dataSource.apply(snapshot, animatingDifferences: false)
      @UIBinding var selectedCategory: String? = "Weather"
      tableView.bind(selection: $selectedCategory, dataSource: dataSource)
      #expect(tableView.selectedRow == 2)

      tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
      #expect(selectedCategory == "Colors")
    }

    /// An outline reports its selection under its own notification name, not the table's.
    @Test("an outline view's selection stays in step with its binding")
    func outlineViewSelectionStaysInStep() async {
      let tree = Tree.fruitsAndVegetables
      let outlineView = makeOutlineView(dataSource: tree)
      outlineView.expandItem(tree.node(named: "Fruits"))
      @UIBinding var selection: String? = "Pear"
      bindSelection($selection, of: outlineView, in: tree)
      #expect(outlineView.selectedRow == 2)

      // NB: What the outline does when the user clicks a row.
      outlineView.selectRowIndexes(IndexSet(integer: 3), byExtendingSelection: false)
      #expect(selection == "Vegetables")
    }

    @Test("collapsing the parent of the selected item clears the binding")
    func collapsingTheSelectedItemsParentClearsTheSelection() async {
      let tree = Tree.fruitsAndVegetables
      let outlineView = makeOutlineView(dataSource: tree)
      outlineView.expandItem(tree.node(named: "Fruits"))
      @UIBinding var selection: String? = "Apple"
      bindSelection($selection, of: outlineView, in: tree)
      #expect(outlineView.selectedRow == 1)

      outlineView.collapseItem(tree.node(named: "Fruits"))

      #expect(selection == nil)
    }

    // MARK: - Expansion

    @Test("an outline view's expanded items stay in step with their binding")
    func expandedItemsStayInStep() async {
      let tree = Tree.nestedFruitsAndVegetables
      let outlineView = makeOutlineView(dataSource: tree)
      @UIBinding var expandedItems: Set<String> = ["Fruits", "Citrus"]
      bindExpandedItems($expandedItems, of: outlineView)
      // NB: Citrus only has a row once Fruits is expanded.
      #expect(outlineView.isItemExpanded(tree.node(named: "Fruits")))
      #expect(outlineView.isItemExpanded(tree.node(named: "Citrus")))
      #expect(!outlineView.isItemExpanded(tree.node(named: "Vegetables")))

      expandedItems = ["Citrus", "Vegetables"]
      await Task.yield()
      #expect(!outlineView.isItemExpanded(tree.node(named: "Fruits")))
      #expect(outlineView.isItemExpanded(tree.node(named: "Vegetables")))

      // NB: What the outline does when the user clicks a disclosure triangle.
      outlineView.expandItem(tree.node(named: "Fruits"))
      #expect(expandedItems == ["Fruits", "Citrus", "Vegetables"])

      outlineView.collapseItem(tree.node(named: "Vegetables"))
      #expect(expandedItems == ["Fruits", "Citrus"])
    }

    @Test("unbinding an outline view's expanded items stops writing to the binding")
    func unbindingTheExpandedItemsStopsWriting() {
      let tree = Tree.nestedFruitsAndVegetables
      let outlineView = makeOutlineView(dataSource: tree)
      @UIBinding var expandedItems: Set<String> = []
      bindExpandedItems($expandedItems, of: outlineView)

      outlineView.unbindExpandedItems()
      outlineView.expandItem(tree.node(named: "Fruits"))

      #expect(expandedItems.isEmpty)
    }

    // MARK: - Helpers

    private func bindExpandedItems(_ expandedItems: UIBinding<Set<String>>, of outlineView: NSOutlineView) {
      outlineView.bind(
        expandedItems: expandedItems,
        itemIdentifier: { [weak outlineView] row in
          (outlineView?.item(atRow: row) as? Node)?.name
        }
      )
    }

    private func bindSelection(
      _ selection: UIBinding<String?>, of outlineView: NSOutlineView, in tree: Tree
    ) {
      outlineView.bind(
        selection: selection,
        row: { [weak outlineView] name in outlineView?.row(forItem: tree.node(named: name)) },
        itemIdentifier: { [weak outlineView] row in
          (outlineView?.item(atRow: row) as? Node)?.name
        }
      )
    }

    private func makeTableView(dataSource: some NSTableViewDataSource) -> NSTableView {
      let tableView = NSTableView()
      tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column")))
      tableView.dataSource = dataSource
      retain(dataSource, by: tableView)
      tableView.reloadData()
      return tableView
    }

    private func makeOutlineView(dataSource: some NSOutlineViewDataSource) -> NSOutlineView {
      let outlineView = NSOutlineView()
      let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column"))
      outlineView.addTableColumn(column)
      outlineView.outlineTableColumn = column
      outlineView.dataSource = dataSource
      retain(dataSource, by: outlineView)
      outlineView.reloadData()
      return outlineView
    }

    /// A table only holds its data source weakly, and a test may stop using its data source long
    /// before the table is done with it.
    private func retain(_ dataSource: AnyObject, by tableView: NSTableView) {
      objc_setAssociatedObject(
        tableView, Self.dataSourceKey, dataSource, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }

    private static let dataSourceKey = malloc(1)!

    /// A table's rows, with nothing in them.
    private final class RowCount: NSObject, NSTableViewDataSource {
      let count: Int

      init(_ count: Int) {
        self.count = count
      }

      func numberOfRows(in tableView: NSTableView) -> Int {
        count
      }
    }

    private final class Node: NSObject {
      let name: String
      let children: [Node]

      init(_ name: String, children: [Node] = []) {
        self.name = name
        self.children = children
      }
    }

    /// An outline's items.
    private final class Tree: NSObject, NSOutlineViewDataSource {
      let roots: [Node]

      init(_ roots: [Node]) {
        self.roots = roots
      }

      /// Fruits, with Apple and Pear inside, then Vegetables, with Carrot inside.
      static var fruitsAndVegetables: Tree {
        Tree([
          Node("Fruits", children: [Node("Apple"), Node("Pear")]),
          Node("Vegetables", children: [Node("Carrot")]),
        ])
      }

      /// Fruits, with Apple and Citrus inside and Lemon inside Citrus, then Vegetables, with Carrot
      /// inside.
      static var nestedFruitsAndVegetables: Tree {
        Tree([
          Node("Fruits", children: [Node("Apple"), Node("Citrus", children: [Node("Lemon")])]),
          Node("Vegetables", children: [Node("Carrot")]),
        ])
      }

      func node(named name: String) -> Node? {
        var pending = roots
        while let node = pending.popLast() {
          if node.name == name { return node }
          pending += node.children
        }
        return nil
      }

      func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        (item as? Node)?.children.count ?? roots.count
      }

      func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        (item as? Node)?.children[index] ?? roots[index]
      }

      func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        !((item as? Node)?.children.isEmpty ?? true)
      }
    }
  }
#endif
