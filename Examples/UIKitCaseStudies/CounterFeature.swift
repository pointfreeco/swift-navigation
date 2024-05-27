import SwiftUI
import UIKitNavigation

@MainActor
@Perceptible
class CounterModel: Hashable {
  var count = 0

  func decrementButtonTapped() {
    count -= 1
  }

  func incrementButtonTapped() {
    count += 1
  }

  nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
  nonisolated static func == (lhs: CounterModel, rhs: CounterModel) -> Bool {
    lhs === rhs
  }
}

final class CounterViewController: UIViewController {
  let model: CounterModel

  init(model: CounterModel) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    let countLabel = UILabel()
    countLabel.textAlignment = .center
    let decrementButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        guard let self else { return }
        model.decrementButtonTapped()
      })
    decrementButton.setTitle("Decrement", for: .normal)
    let incrementButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        guard let self else { return }
        model.incrementButtonTapped()
        if #available(iOS 17, *) {
          traitCollection.dismiss()
        } else {
          // Fallback on earlier versions
        }
      })
    incrementButton.setTitle("Increment", for: .normal)
    let pushCollectionButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        guard let self else { return }
        navigationController?.push(value: AppModel.Path.collection(CollectionModel()))
      })
    pushCollectionButton.setTitle("Push collection feature", for: .normal)
    let pushCounterButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        guard let self else { return }
        navigationController?.push(value: AppModel.Path.counter(CounterModel()))
      })
    pushCounterButton.setTitle("Push counter feature", for: .normal)
    let pushFormButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        guard let self else { return }
        navigationController?.push(value: AppModel.Path.form(FormModel()))
      })
    pushFormButton.setTitle("Push form feature", for: .normal)
    let counterStack = UIStackView(arrangedSubviews: [
      countLabel,
      decrementButton,
      incrementButton,
      pushCollectionButton,
      pushCounterButton,
      pushFormButton,
    ])
    counterStack.axis = .vertical
    counterStack.spacing = 12
    counterStack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(counterStack)
    NSLayoutConstraint.activate([
      counterStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      counterStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      counterStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      counterStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])

    observe { [weak self] in
      guard let self else { return }

      countLabel.text = "\(model.count)"
      navigationItem.title = "Counter: \(model.count)"
    }
  }
}

#Preview {
  UIViewControllerRepresenting {
    CounterViewController(model: CounterModel())
  }
}
