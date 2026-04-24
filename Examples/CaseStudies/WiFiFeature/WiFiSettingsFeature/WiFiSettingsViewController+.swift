#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

import CasePaths

extension NSDiffableDataSourceSnapshot<
    WiFiSettingsViewController.Section,
    WiFiSettingsViewController.Item
> {
    @MainActor
    init(model: WiFiSettingsModel) {
        self.init()

        appendSections([.top])
        appendItems([.isOn], toSection: .top)

        guard model.isOn
        else { return }

        if let selectedNetworkID = model.selectedNetworkID {
            appendItems([.selectedNetwork(selectedNetworkID)], toSection: .top)
        }

        appendSections([.foundNetworks])
        appendItems(
            model.foundNetworks
                .sorted { lhs, rhs in
                    (lhs.isSecured ? 1 : 0, lhs.connectivity)
                        > (rhs.isSecured ? 1 : 0, rhs.connectivity)
                }
                .compactMap { network in
                    network.id == model.selectedNetworkID
                        ? nil
                        : .foundNetwork(network)
                },
            toSection: .foundNetworks
        )
    }
}

extension WiFiSettingsViewController {
    enum Section: Hashable, Sendable {
        case top
        case foundNetworks
    }

    @CasePathable
    @dynamicMemberLookup
    enum Item: Hashable, Sendable {
        case isOn
        case selectedNetwork(Network.ID)
        case foundNetwork(Network)
    }
}

