import Foundation
import CasePaths

@Observable
@MainActor
class WiFiSettingsModel {
    var destination: Destination? {
        didSet { bind() }
    }

    var foundNetworks: [Network]
    var isOn: Bool
    var selectedNetworkID: Network.ID?

    @CasePathable
    enum Destination {
        case connect(ConnectToNetworkModel)
        case detail(NetworkDetailModel)
    }

    init(
        foundNetworks: [Network] = [],
        isOn: Bool = true,
        selectedNetworkID: Network.ID? = nil
    ) {
        self.foundNetworks = foundNetworks
        self.isOn = isOn
        self.selectedNetworkID = selectedNetworkID
        bind()
    }

    private func bind() {
        switch destination {
        case let .connect(model):
            model.onConnect = { [weak self] network in
                guard let self else { return }
                destination = nil
                selectedNetworkID = network.id
            }
            model.onCancel = { [weak self] in
                guard let self else { return }
                destination = nil
            }

        case let .detail(model):
            model.onConfirmForget = { [weak self] in
                guard let self else { return }
                self.destination = nil
                self.selectedNetworkID = nil
            }

        case .none:
            break
        }
    }

    func infoButtonTapped(network: Network) {
        destination = .detail(
            NetworkDetailModel(
                network: network,
                selectedNetworkID: selectedNetworkID
            )
        )
    }

    func networkTapped(_ network: Network) {
        if network.id == selectedNetworkID {
            infoButtonTapped(network: network)
        } else if network.isSecured {
            destination = .connect(ConnectToNetworkModel(network: network))
        } else {
            selectedNetworkID = network.id
        }
    }
}
