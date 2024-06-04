import SwiftUI
import UIKitNavigation

@MainActor
@Perceptible
final class FormModel: HashableObject {
  enum Focus: Hashable {
    case attributedText
    case text
  }

  var attributedText = try! AttributedString(markdown: "Hello, **world**!")
  var color: UIColor? = .white
  var date = Date()
  var focus: Focus?
  var isOn = false
  var isDrillDownPresented = false
  var isSheetPresented = false
  var sheet: Sheet?
  var sliderValue: Float = 0.5
  var stepperValue: Double = 5
  var text = "Blob"

  struct Sheet: Identifiable {
    var text = "Hi"
    var id: String { text }
  }
}

extension UITextField {
  func focus<Value: Hashable>(_ focus: UIBinding<Value?>, equals value: Value) {
    observe { [weak self] in
      guard let self else { return }
      switch (focus.wrappedValue, isFirstResponder) {
      case (value, false):
        becomeFirstResponder()
      case (nil, true):
        resignFirstResponder()
      default:
        break
      }
    }
    addAction(
      UIAction { _ in
        focus.wrappedValue = value
      },
      for: .editingDidBegin
    )
    addAction(
      UIAction { _ in
        guard focus.wrappedValue == value else { return }
        focus.wrappedValue = nil
      },
      for: [.editingDidEnd, .editingDidEndOnExit]
    )
  }
}

extension UIBinding where Value == NSAttributedString {
  fileprivate init(_ base: UIBinding<AttributedString>) {
    self = base.toNSAttributedString
  }
}

extension AttributedString {
  fileprivate var toNSAttributedString: NSAttributedString {
    get { NSAttributedString(self) }
    set { self = AttributedString(newValue) }
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

    let mySlider = UISlider(value: $model.sliderValue)

    let myStepper = UIStepper(value: $model.stepperValue)

    let mySwitch = UISwitch(isOn: $model.isOn)

    let myTextField = UITextField(text: $model.text)
    myTextField.borderStyle = .roundedRect
    myTextField.focus($model.focus, equals: .text)

    let myAttributedTextField = UITextField(attributedText: UIBinding($model.attributedText))
    myAttributedTextField.allowsEditingTextAttributes = true
    myAttributedTextField.borderStyle = .roundedRect
    myAttributedTextField.focus($model.focus, equals: .attributedText)

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
      myLabel.text = """
        MyModel(
          attributedText: \(String(model.attributedText.characters).description),
          color: \(model.color.map(String.init(describing:)) ?? "nil"),
          date: \(model.date),
          focus: \(model.focus.map(String.init(describing:)) ?? "nil"),
          isOn: \(model.isOn),
          sliderValue: \(model.sliderValue),
          stepperValue: \(model.stepperValue),
          text: \(model.text.description)
        )
        """
    }

    navigationController?.pushViewController(isPresented: $model.isDrillDownPresented) {
      ChildController()
    }

    present(item: $model.sheet) { item in
      UINavigationController(rootViewController: ChildController(text: item.text))
    }

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.topAnchor),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      myColorWell.heightAnchor.constraint(equalToConstant: 50),
    ])
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

    if #available(iOS 17, *) {
      navigationItem.rightBarButtonItem = UIBarButtonItem(
        title: "Dismiss",
        primaryAction: UIAction { [weak self] _ in self?.traitCollection.dismiss() }
      )
    }

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
}
