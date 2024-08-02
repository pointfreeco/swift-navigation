import ConcurrencyExtras
import UIKit
import UIKitNavigation

class MinimalObservationViewController: UIViewController, UIKitCaseStudy {
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

    let countLabel = UILabel()
    let incrementButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.model.count += 1
      })
    incrementButton.setTitle("Increment", for: .normal)
    let isCountHiddenSwitch = UISwitch(isOn: $model.isCountHidden)
    let isCountHiddenLabel = UILabel()
    isCountHiddenLabel.text = "Is count hidden?"
    let viewRenderLabel = UILabel()

    let stack = UIStackView(arrangedSubviews: [
      countLabel,
      incrementButton,
      isCountHiddenLabel,
      isCountHiddenSwitch,
      viewRenderLabel,
    ])
    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
        countLabel.text = model.count.description
      }
      countLabel.isHidden = model.isCountHidden
      viewRenderLabel.text = "# of view renders: \(viewRenderCount.value)"
    }
  }

  @Observable
  class Model {
    var count = 0
    var isCountHidden = false
  }
}

#Preview {
  UINavigationController(
    rootViewController: MinimalObservationViewController()
  )
}
