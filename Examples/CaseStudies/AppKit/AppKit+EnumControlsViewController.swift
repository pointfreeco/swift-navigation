#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import AppKitNavigation

class EnumControlsViewController: XiblessViewController<NSView>, AppKitCaseStudy {
  let caseStudyNavigationTitle = "Enum controls"
  let caseStudyTitle = "Concise enum controls"
  let readMe = """
  This case study demonstrates how to drive form controls from bindings to enum state. In this \
  example, a single `Status` enum holds two cases:

  • An integer quantity for when an item is in stock, which can drive a stepper.
  • A Boolean for whether an item is on back order when it is _not_ in stock, which can drive a \
  switch.

  This library provides tools to chain deeper into a binding's case by applying the \
  `@CasePathable` macro.
  """

  @CasePathable
  enum Status {
    case inStock(quantity: Int)
    case outOfStock(isOnBackOrder: Bool)
  }

  @UIBinding var status: Status = .inStock(quantity: 100)

  override func viewDidLoad() {
    super.viewDidLoad()

    let quantityLabel = NSTextField(labelWithString: "")
    let quantityStepper = NSStepper()
    quantityStepper.maxValue = .infinity
    let quantityStack = NSStackView(views: [
      quantityLabel,
      quantityStepper,
    ])
    let outOfStockButton = NSButton()
    outOfStockButton.addAction { [weak self] _ in
      self?.status = .outOfStock(isOnBackOrder: false)
    }
    outOfStockButton.title = "Out of stock"
    let inStockStack = NSStackView(views: [
      quantityStack,
      outOfStockButton,
    ])
    inStockStack.orientation = .vertical

    let isOnBackOrderLabel = NSTextField(labelWithString: "Is on back order?")
    let isOnBackOrderSwitch = NSSwitch()
    let isOnBackOrderStack = NSStackView(views: [
      isOnBackOrderLabel,
      isOnBackOrderSwitch,
    ])
    let backInStockButton = NSButton()
    backInStockButton.addAction { [weak self] _ in
      self?.status = .inStock(quantity: 100)
    }

    backInStockButton.title = "Back in stock!"
    let outOfStockStack = NSStackView(views: [
      isOnBackOrderStack,
      backInStockButton,
    ])
    outOfStockStack.orientation = .vertical

    let stack = NSStackView(views: [
      inStockStack,
      outOfStockStack,
    ])
    stack.orientation = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])

    observe { [weak self] in
      guard let self else { return }

      inStockStack.isHidden = !status.is(\.inStock)
      outOfStockStack.isHidden = !status.is(\.outOfStock)

      switch status {
      case .inStock:
        if let quantity = $status.inStock {
          quantityLabel.stringValue = "Quantity: \(quantity.wrappedValue)"
          quantityStepper.bind(value: quantity.asDouble)
        }

      case .outOfStock:
        if let isOnBackOrder = $status.outOfStock {
          isOnBackOrderSwitch.bind(isOn: isOnBackOrder)
        }
      }
    }
  }
}

@available(macOS 14.0, *)
#Preview {
  EnumControlsViewController()
}

extension Int {
  fileprivate var asDouble: Double {
    get { Double(self) }
    set { self = Int(newValue) }
  }
}

#endif
