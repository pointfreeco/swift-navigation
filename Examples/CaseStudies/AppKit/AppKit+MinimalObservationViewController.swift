#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import AppKitNavigation
import ConcurrencyExtras

class MinimalObservationViewController: XiblessViewController<NSView>, AppKitCaseStudy {
    let caseStudyTitle = "Minimal observation"
    let readMe = """
    This case study demonstrates how to use the 'observe' tool from the library in order to \
    minimally observe changes to an @Observable model.

    To see this, tap the "Increment" button to see that the view re-renders each time you count \
    up. Then, hide the counter and increment again to see that the view does not re-render, even \
    though the count is changing. This shows that only the state accessed inside the trailing \
    closure of 'observe' causes re-renders.
    """
    @UIBindable var model = Model()

    override func viewDidLoad() {
        super.viewDidLoad()

        let countLabel = NSTextField(labelWithString: "")
        let incrementButton = NSButton(title: "Increment", target: self, action: #selector(incrementButtonAction(_:)))
        let isCountHiddenSwitch = NSSwitch(isOn: $model.isCountHidden)
        let isCountHiddenLabel = NSTextField(labelWithString: "Is count hidden?")
        let viewRenderLabel = NSTextField(labelWithString: "")
        let stack = NSStackView(views: [
            countLabel,
            incrementButton,
            isCountHiddenLabel,
            isCountHiddenSwitch,
            viewRenderLabel,
        ])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        let viewRenderCount = LockIsolated(0)
        observe { [weak self] in
            guard let self else { return }
            viewRenderCount.withValue { $0 += 1 }

            if !model.isCountHidden {
                // NB: We do not access 'model.count' when the count is hidden, and therefore its mutations
                //     will not cause a re-render of the view.
                countLabel.stringValue = model.count.description
            }
            countLabel.isHidden = model.isCountHidden
            viewRenderLabel.stringValue = "# of view renders: \(viewRenderCount.value)"
        }
    }

    @objc func incrementButtonAction(_ sender: NSButton) {
        model.count += 1
    }

    @Observable
    class Model {
        var count = 0
        var isCountHidden = false
    }
}

#Preview {
    MinimalObservationViewController()
}

#endif
