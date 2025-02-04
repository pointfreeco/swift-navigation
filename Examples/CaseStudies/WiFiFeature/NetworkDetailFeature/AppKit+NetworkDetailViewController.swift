#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import AppKitNavigation

final class NetworkDetailViewController: XiblessViewController<NSView> {
    @UIBindable var model: NetworkDetailModel

    init(model: NetworkDetailModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

//        navigationItem.title = model.network.name

        let forgetButton = NSButton { [weak self] _ in
            guard let self else { return }
            model.forgetNetworkButtonTapped()
        }

        forgetButton.title = "Forget network"
//        forgetButton.hasDestructiveAction = true
        forgetButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(forgetButton)
        NSLayoutConstraint.activate([
            forgetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            forgetButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        observe { [weak self] in
            guard let self else { return }

//            forgetButton.isHidden = model.network.id != model.selectedNetworkID
        }

        modal(isModaled: $model.forgetAlertIsPresented) { [unowned self] in
            let alert = NSAlert()
            alert.messageText = "Forget Wi-Fi Network “\(model.network.name)”?"
            alert.informativeText = """
            Your Mac and other devices using iCloud Keychain will no longer join this Wi-Fi \
            network.
            """
            
            alert.addButton(ButtonState<Void>(role: .cancel) { TextState("Cancel") }) { _ in }
            alert.addButton(ButtonState<Void>(role: .destructive) { TextState("Forget") }) { [weak self] _ in
                guard let self else { return }
                model.confirmForgetNetworkButtonTapped()
            }
            return alert
        }
    }
}

#Preview {
    NetworkDetailViewController(
        model: NetworkDetailModel(
            network: Network(name: "Blob's WiFi"),
            selectedNetworkID: UUID()
        )
    )
}
#endif
