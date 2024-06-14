import SwiftUI
import UIKitNavigation

@MainActor
@Perceptible
final class FormModel: HashableObject {
  var attributedText: NSAttributedString = .mock
  var attributedTextSelection: UITextSelection?
  var color: UIColor? = .white
  var date = Date()
  var focus: Focus?
  var isOn = false
  var isDrillDownPresented = false
  var segment = Segment.columnA
  var sheet: Sheet?
  var sliderValue: Float = 0.5
  var stepperValue: Double = 5
  var text = "Blob"
  var textSelection: UITextSelection?

  enum Focus: Hashable {
    case attributedText
    case text
  }

  enum Segment: Int, CaseIterable {
    case columnA
    case columnB
  }

  struct Sheet: Identifiable {
    var text = "Hi"
    var id: String { text }
  }
}

@MainActor
final class FormViewController: UIViewController {
  @UIBindable var model: FormModel

  init(model: FormModel) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let myColorWell = UIColorWell(selectedColor: $model.color)

    let myDatePicker = UIDatePicker(date: $model.date)

    let mySegmentControl = UISegmentedControl()
    for (index, segment) in FormModel.Segment.allCases.enumerated() {
      mySegmentControl.insertSegment(withTitle: "\(segment)", at: index, animated: false)
    }
    mySegmentControl.bind(selectedSegment: $model.segment)

    let mySlider = UISlider(value: $model.sliderValue)

    let myStepper = UIStepper(value: $model.stepperValue)

    let mySwitch = UISwitch(isOn: $model.isOn)

    let myTextField = UITextField(text: $model.text)
    myTextField.bind(focus: $model.focus, equals: .text)
    myTextField.bind(selection: $model.textSelection)
    myTextField.borderStyle = .roundedRect

    let myAttributedTextField = UITextField(attributedText: $model.attributedText)
    myAttributedTextField.allowsEditingTextAttributes = true
    myAttributedTextField.bind(focus: $model.focus, equals: .attributedText)
    myAttributedTextField.bind(selection: $model.attributedTextSelection)
    myAttributedTextField.borderStyle = .roundedRect

    let sheetButton = UIButton(
      configuration: .plain(),
      primaryAction: UIAction { [weak self] _ in
        self?.model.sheet = .init(text: "Blob")
        Task {
          try await Task.sleep(for: .seconds(2))
          self?.model.sheet? = .init(text: "Blob, Jr.")
        }
      }
    )
    sheetButton.setTitle("Present sheet", for: .normal)

    let drillDownButton = UIButton(
      configuration: .plain(),
      primaryAction: UIAction { [weak self] _ in self?.model.isDrillDownPresented = true }
    )
    drillDownButton.setTitle("Present drill-down", for: .normal)

    let myLabel = UILabel()
    myLabel.numberOfLines = 0

    let stack = UIStackView(arrangedSubviews: [
      myColorWell,
      myDatePicker,
      mySegmentControl,
      mySlider,
      myStepper,
      mySwitch,
      myTextField,
      myAttributedTextField,
      myLabel,
      sheetButton,
      drillDownButton,
    ])
    stack.axis = .vertical
    stack.isLayoutMarginsRelativeArrangement = true
    stack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    observe { [weak self] in
      guard let self else { return }

      view.backgroundColor = model.color

      let attributedTextSelection = model.attributedTextSelection.map {
        self.model.attributedText.string.range(for: $0.range)
      }
      let textSelection = model.textSelection.map {
        self.model.text.range(for: $0.range)
      }

      myLabel.text = """
        MyModel(
          attributedText: \(model.attributedText.string.debugDescription),
          attributedTextSelection: \
        \(attributedTextSelection.map(String.init(describing:)) ?? "nil"),
          color: \(model.color.map(String.init(describing:)) ?? "nil"),
          date: \(model.date),
          focus: \(model.focus.map(String.init(describing:)) ?? "nil"),
          isDrillDownPresented: \(model.isDrillDownPresented),
          isOn: \(model.isOn),
          segment: \(model.segment),
          sheet: \(model.sheet.map(String.init(describing:)) ?? "nil"),
          sliderValue: \(model.sliderValue),
          stepperValue: \(model.stepperValue),
          text: \(model.text.debugDescription),
          textSelection: \(textSelection.map(String.init(describing:)) ?? "nil")
        )
        """
    }

    navigationController?.pushViewController(isPresented: $model.isDrillDownPresented) {
      ChildController()
    }

    present(item: $model.sheet) { item in
      let vc = UINavigationController(rootViewController: ChildController(text: item.text))
      if let sheet = vc.sheetPresentationController {
        sheet.detents = [.medium()]
        sheet.largestUndimmedDetentIdentifier = .medium
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.prefersEdgeAttachedInCompactHeight = true
        sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
      }
      return vc
    }

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.topAnchor),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      myColorWell.heightAnchor.constraint(equalToConstant: 50),
    ])

    Task { [weak self] in
      try await Task.sleep(for: .seconds(1))

      guard let self else { return }
      model.textSelection = UITextSelection(
        insertionPoint: "text".index(after: "text".startIndex)
      )
    }
  }
}

private extension String {
  func range(for range: Range<String.Index>) -> Range<Int> {
    distance(from: startIndex, to: range.lowerBound)
    ..<
    distance(from: startIndex, to: range.upperBound)
  }
}

final class ChildController: UIViewController {
  let text: String
  init(text: String = "Hello!") {
    self.text = text
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground
    let label = UILabel()
    label.text = text
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // NB: Parent traits aren't propagated yet in `viewDidLoad`
    if #available(iOS 17, *), traitCollection.isPresented {
      var dismissButton: UIBarButtonItem {
        UIBarButtonItem(
          title: "Dismiss",
          primaryAction: UIAction { [weak self] _ in self?.traitCollection.dismiss() }
        )
      }
      navigationItem.rightBarButtonItem = traitCollection.isPresented ? dismissButton : nil
    }
  }
}

extension NSAttributedString {
  fileprivate static var mock: NSAttributedString {
    let base = UIFont.preferredFont(forTextStyle: .body)
    let font = UIFont(
      descriptor: base.fontDescriptor.withSymbolicTraits(.traitBold) ?? base.fontDescriptor,
      size: base.pointSize
    )
    let name = NSAttributedString(string: "Blob, Jr.", attributes: [.font: font])
    let string = NSMutableAttributedString(string: "Hello, ")
    string.append(name)
    string.append(NSAttributedString(string: "!"))
    return string
  }
}
