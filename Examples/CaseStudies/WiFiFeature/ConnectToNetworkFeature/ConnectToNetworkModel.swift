import Foundation
import IssueReporting

@Observable
@MainActor
class ConnectToNetworkModel: Identifiable {
    var incorrectPasswordAlertIsPresented = false
    var isConnecting = false
    var onCancel: () -> Void = {
        reportIssue("ConnectToNetworkModel.onCancel unimplemented.")
    }
    var onConnect: (Network) -> Void = { _ in
        reportIssue("ConnectToNetworkModel.onConnect unimplemented.")
    }

    let network: Network
    var password = ""
    init(network: Network) {
        self.network = network
    }

    func cancelButtonTapped() {
        onCancel()
    }
    
    func joinButtonTapped() async {
        isConnecting = true
        defer { isConnecting = false }
        try? await Task.sleep(for: .seconds(1))
        if password == "blob" {
            onConnect(network)
        } else {
            incorrectPasswordAlertIsPresented = true
        }
    }
}
