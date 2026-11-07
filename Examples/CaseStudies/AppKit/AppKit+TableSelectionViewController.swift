#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

class TableSelectionViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyTitle = "Table and outline selection"
  let readMe = """
  A table or an outline binds its selected row to the identifier of the selected item, and an \
  outline binds the items it has expanded to a set of identifiers. The model holds identifiers \
  rather than rows, so it does not have to know how the rows are laid out.

  The table uses a diffable data source, which the binding asks for rows directly. The outline \
  uses a data source of its own and gives the binding its row lookups. The buttons change the \
  model; clicking in the table or the outline changes it too.
  """
  @UIBindable var model = Model()
  private let tableView = NSTableView()
  private let outlineView = NSOutlineView()
  private let outlineDataSource = PantryOutlineDataSource()
  private var tableDataSource: NSTableViewDiffableDataSource<Int, String>?

  override func viewDidLoad() {
    super.viewDidLoad()

    // MARK: Table

    let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Planet"))
    tableColumn.title = "Planet"
    tableView.addTableColumn(tableColumn)
    let tableDataSource = NSTableViewDiffableDataSource<Int, String>(tableView: tableView) {
      _, _, _, planet in
      NSTextField(labelWithString: planet)
    }
    var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
    snapshot.appendSections([0])
    snapshot.appendItems(["Mercury", "Venus", "Earth", "Mars", "Jupiter"])
    tableDataSource.apply(snapshot, animatingDifferences: false)
    self.tableDataSource = tableDataSource
    tableView.bind(selection: $model.selectedPlanet, dataSource: tableDataSource)

    // MARK: Outline

    // NB: Captured weakly below: the outline keeps its bindings, and the bindings keep these
    //     closures.
    let outlineView = self.outlineView
    let outlineDataSource = self.outlineDataSource
    let outlineColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Item"))
    outlineColumn.title = "Pantry"
    outlineView.addTableColumn(outlineColumn)
    outlineView.outlineTableColumn = outlineColumn
    outlineView.dataSource = outlineDataSource
    outlineView.delegate = outlineDataSource
    outlineView.bind(
      selection: $model.selectedPantryItem,
      row: { [weak outlineView, weak outlineDataSource] name in
        guard let outlineView, let node = outlineDataSource?.node(named: name) else { return nil }
        return outlineView.row(forItem: node)
      },
      itemIdentifier: { [weak outlineView] row in
        (outlineView?.item(atRow: row) as? PantryNode)?.name
      }
    )
    outlineView.bind(
      expandedItems: $model.expandedPantryGroups,
      itemIdentifier: { [weak outlineView] row in
        (outlineView?.item(atRow: row) as? PantryNode)?.name
      }
    )

    let statusLabel = NSTextField(wrappingLabelWithString: "")
    statusLabel.textColor = .secondaryLabelColor

    addColumn(
      of: [
        makeSectionLabel("Table"),
        Self.scrollView(containing: tableView),
        makeButton("Select Mars") { [weak self] in
          self?.model.selectedPlanet = "Mars"
        },
        makeButton("Clear the table's selection") { [weak self] in
          self?.model.selectedPlanet = nil
        },
        makeSectionLabel("Outline"),
        Self.scrollView(containing: outlineView),
        makeButton("Select Cherries") { [weak self] in
          // NB: Expanded too, since a row only exists while its group is expanded.
          self?.model.expandedPantryGroups.insert("Fruit")
          self?.model.selectedPantryItem = "Cherries"
        },
        makeButton("Expand everything") { [weak self] in
          self?.model.expandedPantryGroups = Set(PantryOutlineDataSource.groupNames)
        },
        makeButton("Collapse everything") { [weak self] in
          self?.model.expandedPantryGroups = []
        },
        statusLabel,
      ],
      to: view
    )

    observe { [weak self] in
      guard let self else { return }
      statusLabel.stringValue = """
        Table selection: \(model.selectedPlanet ?? "none")
        Outline selection: \(model.selectedPantryItem ?? "none")
        Expanded groups: \(model.expandedPantryGroups.isEmpty ? "none" : model.expandedPantryGroups.sorted().joined(separator: ", "))
        """
    }
  }

  private static func scrollView(containing tableView: NSTableView) -> NSScrollView {
    tableView.headerView = nil
    let scrollView = NSScrollView()
    scrollView.documentView = tableView
    scrollView.hasVerticalScroller = true
    scrollView.borderType = .bezelBorder
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      scrollView.widthAnchor.constraint(equalToConstant: 260),
      scrollView.heightAnchor.constraint(equalToConstant: 120),
    ])
    return scrollView
  }

  @Observable
  class Model {
    var selectedPlanet: String?
    var selectedPantryItem: String?
    var expandedPantryGroups: Set<String> = ["Vegetables"]
  }
}

/// An item in the outline: a group of the pantry, or something in it.
private final class PantryNode {
  let name: String
  let children: [PantryNode]

  init(_ name: String, children: [PantryNode] = []) {
    self.name = name
    self.children = children
  }
}

/// The outline's data: a fixed tree of groups and the items in them.
@MainActor
private final class PantryOutlineDataSource: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
  static let groupNames = ["Fruit", "Vegetables"]

  private let groups = [
    PantryNode("Fruit", children: [PantryNode("Apples"), PantryNode("Cherries")]),
    PantryNode("Vegetables", children: [PantryNode("Carrots"), PantryNode("Leeks")]),
  ]

  /// The node with the given name, wherever it is in the tree.
  func node(named name: String) -> PantryNode? {
    for group in groups {
      if group.name == name { return group }
      if let child = group.children.first(where: { $0.name == name }) { return child }
    }
    return nil
  }

  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    (item as? PantryNode)?.children.count ?? groups.count
  }

  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    (item as? PantryNode)?.children[index] ?? groups[index]
  }

  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    !((item as? PantryNode)?.children.isEmpty ?? true)
  }

  func outlineView(
    _ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any
  ) -> NSView? {
    NSTextField(labelWithString: (item as? PantryNode)?.name ?? "")
  }
}

#Preview {
  TableSelectionViewController()
}
#endif
