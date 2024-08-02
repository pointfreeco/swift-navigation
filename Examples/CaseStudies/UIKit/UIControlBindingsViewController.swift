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
      myLabel,
    ])
    stack.axis = .vertical
    stack.isLayoutMarginsRelativeArrangement = true
    stack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    stack.spacing = 12
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

      let textSelection = model.textSelection.map {
        self.model.text.range(for: $0.range)
      }

      myLabel.text = """
        MyModel(
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

extension String {
  fileprivate func range(for range: Range<String.Index>) -> Range<Int> {
    distance(
      from: startIndex, to: range.lowerBound)..<distance(from: startIndex, to: range.upperBound)
  }
}

#Preview {
  UINavigationController(
    rootViewController: UIControlBindingsViewController()
  )
}
