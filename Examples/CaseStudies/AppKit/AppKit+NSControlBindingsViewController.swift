#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation

class XiblessViewController<View: NSView>: NSViewController {
    lazy var contentView = View()

    override func loadView() {
        view = contentView
    }

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("")
    }
}

class NSControlBindingsViewController: XiblessViewController<NSBox>, AppKitCaseStudy {
    let caseStudyTitle = "NSControl bindings"
    let readMe = """
    This demonstrates how to use the library's `@UIBinding` and `@UIBindable` property wrappers \
    to bind an observable model to various `NSControl`s. For the most part it works exactly \
    as it does in SwiftUI. Just use `$model` to construct an object that can derive bindings, \
    and then use simple dot-syntax to decide which field you want to derive a binding for.
    """
    @UIBindable var model = Model()

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.boxType = .custom
        contentView.borderWidth = 0
        let colorWell = NSColorWell(color: $model.color)
        let datePicker = NSDatePicker(date: $model.date)
        let segmentControl = NSSegmentedControl(labels: Model.Segment.allCases.map { "\($0)" }, trackingMode: .selectOne, target: nil, action: nil)
        segmentControl.bind(selectedSegment: $model.segment)
        let slider = NSSlider(value: $model.sliderValue)
        let stepper = NSStepper(value: $model.stepperValue)
        let `switch` = NSSwitch(isOn: $model.isOn)
        let textField = NSTextField(text: $model.text)
        textField.bind(focus: $model.focus, equals: .text)
        textField.bind(selection: $model.textSelection)
        textField.bezelStyle = .roundedBezel
        let label = NSTextField(labelWithString: "")
        label.maximumNumberOfLines = 0
        let stack = NSStackView(views: [
            colorWell,
            datePicker,
            segmentControl,
            slider,
            stepper,
            `switch`,
            textField,
            label,
        ])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.contentView?.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            colorWell.heightAnchor.constraint(equalToConstant: 50),
        ])

        observe { [weak self] in
            guard let self else { return }

            contentView.fillColor = model.color

            let textSelection = model.textSelection.map {
                self.model.text.range(for: $0.range)
            }

            label.stringValue = """
            MyModel(
              color: \(model.color.description),
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
        var color: NSColor = .windowBackgroundColor
        var date = Date()
        var focus: Focus?
        var isOn = false
        var segment = Segment.columnA
        var sliderValue: Float = 0.5
        var stepperValue: Double = 5
        var text = "Blob"
        var textSelection: AppKitTextSelection?

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
            from: startIndex, to: range.lowerBound
        ) ..< distance(from: startIndex, to: range.upperBound)
    }
}

#Preview(traits: .fixedLayout(width: 500, height: 800)) {
    NSControlBindingsViewController()
}

#endif
