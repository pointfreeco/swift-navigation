import SwiftUI
import UIKitNavigation
import XCTestDynamicOverlay

@MainActor
@Observable
class NetworkDetailModel {
  var forgetAlertIsPresented = false
  var onConfirmForget: () -> Void = {
    XCTFail("NetworkDetailModel.onConfirmForget unimplemented.")
  }
  let network: Network
  let selectedNetworkID: Network.ID?

  init(
    network: Network,
    selectedNetworkID: Network.ID?
  ) {
    self.network = network
    self.selectedNetworkID = selectedNetworkID
  }

  func forgetNetworkButtonTapped() {
    forgetAlertIsPresented = true
  }

  func confirmForgetNetworkButtonTapped() {
    onConfirmForget()
  }
}

final class NetworkDetailViewController: UIViewController {
  @UIBindable var model: NetworkDetailModel

  init(model: NetworkDetailModel) {
    self.model = model
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.title = model.network.name

    let forgetButton = UIButton(
      type: .system,
      primaryAction: UIAction { [weak self] _ in
        self?.model.forgetNetworkButtonTapped()
      })
    forgetButton.setTitle("Forget network", for: .normal)
    forgetButton.setTitleColor(.red, for: .normal)
    forgetButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(forgetButton)
    NSLayoutConstraint.activate([
      forgetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      forgetButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])

    observe { [weak self] in
      guard let self else { return }

      forgetButton.isHidden = model.network.id != model.selectedNetworkID
    }

    present(isPresented: $model.forgetAlertIsPresented) { [unowned self] in
      let controller = UIAlertController(
        title: "Forget Wi-Fi Network “\(model.network.name)”?",
        message: """
          Your iPhone and other devices using iCloud Keychain will no longer join this Wi-Fi \
          network.
          """,
        preferredStyle: .alert
      )
      controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
      controller.addAction(
        UIAlertAction(title: "Forget", style: .destructive) { [weak self] _ in
          self?.model.confirmForgetNetworkButtonTapped()
        })
      return controller
    }
  }
}

#Preview {
  UIViewControllerRepresenting {
    UINavigationController(
      rootViewController: NetworkDetailViewController(
        model: NetworkDetailModel(
          network: Network(name: "Blob's WiFi"),
          selectedNetworkID: UUID()
        )
      )
    )
  }
}
