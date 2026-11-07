#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

class OptionBindingsViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyTitle = "Options"
  let readMe = """
  Controls that pick one of several options bind to the option itself. The pop-up button, the \
  segmented control and the tabs all follow the same fruit, so picking a fruit in any of them \
  moves the other two.

  A segmented control that lets you pick any number of segments binds each segment to a Bool of \
  its own, and a menu item binds its checkmark to a Bool.
  """
  @UIBindable var model = Model()
  private let tabViewController = NSTabViewController()

  override func viewDidLoad() {
    super.viewDidLoad()

    let popUpButton = NSPopUpButton(selection: $model.fruit, options: Fruit.allCases, title: \.title)
    let segmentedControl = NSSegmentedControl(
      selection: $model.fruit, options: Fruit.allCases, title: \.title
    )

    for fruit in Fruit.allCases {
      let tabViewItem = NSTabViewItem(viewController: FruitViewController(fruit: fruit))
      tabViewItem.label = fruit.title
      tabViewController.addTabViewItem(tabViewItem)
    }
    tabViewController.tabStyle = .segmentedControlOnTop
    // NB: Bound once the tabs are in place: the binding selects the tab of the current option.
    tabViewController.bind(selection: $model.fruit, options: Fruit.allCases)
    addChild(tabViewController)
    let tabView = tabViewController.view
    tabView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tabView.widthAnchor.constraint(equalToConstant: 320),
      tabView.heightAnchor.constraint(equalToConstant: 110),
    ])

    let styleControl = NSSegmentedControl(
      labels: ["Bold", "Italic", "Underline"], trackingMode: .selectAny, target: nil, action: nil
    )
    styleControl.bind(isSelected: $model.isBold, forSegment: 0)
    styleControl.bind(isSelected: $model.isItalic, forSegment: 1)
    styleControl.bind(isSelected: $model.isUnderlined, forSegment: 2)

    let viewOptionsButton = NSPopUpButton(frame: .zero, pullsDown: true)
    viewOptionsButton.addItem(withTitle: "View options")
    viewOptionsButton.menu?.addItem(NSMenuItem(title: "Show the grid", isOn: $model.showsGrid))

    let statusLabel = NSTextField(wrappingLabelWithString: "")
    statusLabel.textColor = .secondaryLabelColor

    addColumn(
      of: [
        makeSectionLabel("One of several options"),
        popUpButton,
        segmentedControl,
        tabView,
        makeSectionLabel("A Bool for each segment"),
        styleControl,
        makeSectionLabel("A menu item's checkmark"),
        viewOptionsButton,
        statusLabel,
      ],
      to: view
    )

    observe { [weak self] in
      guard let self else { return }
      let styles = [
        model.isBold ? "bold" : nil,
        model.isItalic ? "italic" : nil,
        model.isUnderlined ? "underlined" : nil,
      ].compactMap(\.self)
      statusLabel.stringValue = """
        Fruit: \(model.fruit.title)
        Style: \(styles.isEmpty ? "plain" : styles.joined(separator: ", "))
        Grid: \(model.showsGrid ? "shown" : "hidden")
        """
    }
  }

  @Observable
  class Model {
    var fruit = Fruit.banana
    var isBold = true
    var isItalic = false
    var isUnderlined = false
    var showsGrid = false
  }

  enum Fruit: CaseIterable {
    case apple
    case banana
    case cherry

    var title: String {
      switch self {
      case .apple: "Apple"
      case .banana: "Banana"
      case .cherry: "Cherry"
      }
    }
  }
}

/// The content of one tab: the name of its fruit.
private class FruitViewController: XiblessViewController<NSView> {
  private let fruit: OptionBindingsViewController.Fruit

  init(fruit: OptionBindingsViewController.Fruit) {
    self.fruit = fruit
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let label = NSTextField(labelWithString: "This tab is about the \(fruit.title.lowercased()).")
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}

#Preview {
  OptionBindingsViewController()
}
#endif
