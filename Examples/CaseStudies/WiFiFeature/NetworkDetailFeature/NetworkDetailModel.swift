import Foundation
import XCTestDynamicOverlay

@MainActor
@Observable
class NetworkDetailModel: Identifiable {
    var forgetAlertIsPresented = false
    var onConfirmForget: () -> Void = {
        XCTFail("NetworkDetailModel.onConfirmForget unimplemented.")
    }

    let network: Network
    let selectedNetworkID: Network.ID?

    let id = UUID()
    
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
