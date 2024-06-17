import UIKit
import UIKitNavigation

class UIControlBindingsViewController: UIViewController, UIKitCaseStudy {
  let caseStudyTitle = "UIControl bindings"
  let readMe = """
    This demonstrates how to use the library's `@UIBinding` and `@UIBindable` property wrappers \
    to bind an observable model to various `UIControl`s. For the most part it works exactly \
    as it does in SwiftUI. Just use `$model` to construct an object that can derive bindings, \
    and then use simple dot-syntax to decide which field you want to derive a binding for.
    """
  @UIBindable var model = Model()

  override func viewDidLoad() {
    super.viewDidLoad()

    let myColorWell = UIColorWell(selectedColor: $model.color)
    let myDatePicker = UIDatePicker(date: $model.date)
    let mySegmentControl = UISegmentedControl()
    for (index, segment) in Model.Segment.allCases.enumerated() {
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
    ])
    stack.axis = .vertical
    stack.isLayoutMarginsRelativeArrangement = true
    stack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false

    let scroll = UIScrollView()
    scroll.addSubview(stack)
    scroll.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scroll)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: scroll.topAnchor),
      stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
      stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
      scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      scroll.widthAnchor.constraint(equalTo: stack.widthAnchor),
      myColorWell.heightAnchor.constraint(equalToConstant: 50),
    ])

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
          isOn: \(model.isOn),
          segment: \(model.segment),
          sliderValue: \(model.sliderValue),
          stepperValue: \(model.stepperValue),
          text: \(model.text.debugDescription),
          textSelection: \(textSelection.map(String.init(describing:)) ?? "nil")
        )
        """
    }
  }

  @MainActor
  @Observable
  final class Model: HashableObject {
    var attributedText: NSAttributedString = .mock
    var attributedTextSelection: UITextSelection?
    var color: UIColor? = .white
    var date = Date()
    var focus: Focus?
    var isOn = false
    var segment = Segment.columnA
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

#Preview {
  UINavigationController(
    rootViewController: UIControlBindingsViewController()
  )
}
