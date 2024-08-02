import UIKit
import UIKitNavigation

class EnumControlsViewController: UIViewController, UIKitCaseStudy {
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

    let quantityLabel = UILabel()
    let quantityStepper = UIStepper()
    quantityStepper.maximumValue = .infinity
    let quantityStack = UIStackView(arrangedSubviews: [
      quantityLabel,
      quantityStepper,
    ])
    let outOfStockButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.status = .outOfStock(isOnBackOrder: false)
      })
    outOfStockButton.setTitle("Out of stock", for: .normal)
    let inStockStack = UIStackView(arrangedSubviews: [
      quantityStack,
      outOfStockButton,
    ])
    inStockStack.axis = .vertical

    let isOnBackOrderLabel = UILabel()
    isOnBackOrderLabel.text = "Is on back order?"
    let isOnBackOrderSwitch = UISwitch()
    let isOnBackOrderStack = UIStackView(arrangedSubviews: [
      isOnBackOrderLabel,
      isOnBackOrderSwitch,
    ])
    let backInStockButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.status = .inStock(quantity: 100)
      })
    backInStockButton.setTitle("Back in stock!", for: .normal)
    let outOfStockStack = UIStackView(arrangedSubviews: [
      isOnBackOrderStack,
      backInStockButton,
    ])
    outOfStockStack.axis = .vertical

    let stack = UIStackView(arrangedSubviews: [
      inStockStack,
      outOfStockStack,
    ])
    stack.axis = .vertical
    stack.isLayoutMarginsRelativeArrangement = true
    stack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
          quantityLabel.text = "Quantity: \(quantity.wrappedValue)"
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

extension Int {
  fileprivate var asDouble: Double {
    get { Double(self) }
    set { self = Int(newValue) }
  }
}
