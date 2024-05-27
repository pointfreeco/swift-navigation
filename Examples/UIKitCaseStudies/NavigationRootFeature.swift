import UIKit

final class NavigationRootViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    let counterButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
      guard let self else { return }
      navigationController?.push(value: AppModel.Path.counter(CounterModel()))
    })
    counterButton.setTitle("Counter", for: .normal)
    let stack = UIStackView(arrangedSubviews: [
      counterButton
    ])
    stack.axis = .vertical
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}
